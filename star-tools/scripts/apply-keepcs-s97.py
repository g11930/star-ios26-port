#!/usr/bin/env python3
# s97: 让 star_cs_keep_valid 在 SECURE_KERNEL 下真正生效 + 两处只读诊断 IOLog
# 严格锚点 / 幂等 / 自动备份
import hashlib, os, re, sys

ROOT = "/root/star26/star-native"
CS   = os.path.join(ROOT, "bsd/kern/kern_cs.c")
EXEC = os.path.join(ROOT, "bsd/kern/kern_exec.c")

def read(p):
    with open(p, "rb") as f:
        return f.read().decode("utf-8")

def write(p, s):
    with open(p, "wb") as f:
        f.write(s.encode("utf-8"))

def backup(p):
    b = p + ".s97-pre.bak"
    if not os.path.exists(b):
        with open(p, "rb") as f, open(b, "wb") as g:
            g.write(f.read())
        print("backup ->", b)

def md5(p):
    return hashlib.md5(open(p, "rb").read()).hexdigest()

# ---------- 1) kern_cs.c ----------
src = read(CS)
orig_md5 = md5(CS)

A1 = """/* S93: keep CS_VALID across failed page validations (boot-arg gated). */
int star_cs_keep_valid = 0;
static int star_kv_logged = 0;
"""
NEW1 = A1 + """
/* S97: kern_cs.c's cs_init() body (and thus the S93 parse above) is compiled
 * out under SECURE_KERNEL, which is the configuration we boot. Parse the knob
 * unconditionally so star_cs_keep_valid can actually take effect. */
__startup_func
static void
star_cs_keep_valid_init(void)
{
	PE_parse_boot_argn("star_cs_keep_valid", &star_cs_keep_valid,
	    sizeof(star_cs_keep_valid));
}
STARTUP(CODESIGNING, STARTUP_RANK_SECOND, star_cs_keep_valid_init);
"""

A2 = """	flags = proc_getcsflags(p);

	/* XXX for testing */
"""
NEW2 = """	flags = proc_getcsflags(p);
	uint64_t star_iv_before = flags;

	/* XXX for testing */
"""

A3 = """	proc_unlock(p);

	if (verbose) {
		printf("CODE SIGNING: cs_invalid_page(0x%llx): "
"""
NEW3 = """	proc_unlock(p);

	/* S97 diag: which process hits page invalidation and whether the knob is live */
	{
		static unsigned s97_iv_n;
		if (s97_iv_n < 8) {
			s97_iv_n++;
			IOLog("star_iv97: pid %d[%s] before=0x%x after=0x%x keep=%d\\n",
			    proc_getpid(p), p->p_comm, (unsigned)star_iv_before,
			    (unsigned)proc_getcsflags(p), star_cs_keep_valid);
		}
	}

	if (verbose) {
		printf("CODE SIGNING: cs_invalid_page(0x%llx): "
"""

def apply(text, anchor, new, name, marker):
    if marker in text:
        print(f"[skip] {name}: already applied")
        return text
    if text.count(anchor) != 1:
        sys.exit(f"[FATAL] {name}: anchor count={text.count(anchor)} != 1")
    print(f"[ok] {name}")
    return text.replace(anchor, new)

if "star_iv_before" not in src:
    backup(CS)
src = apply(src, A1, NEW1, "keep_valid startup fn", "star_cs_keep_valid_init")
src = apply(src, A2, NEW2, "cs_invalid_page before-flag capture", "star_iv_before")
src = apply(src, A3, NEW3, "cs_invalid_page diag log", "star_iv97")
write(CS, src)
print("kern_cs.c md5:", orig_md5, "->", md5(CS))

# ---------- 2) kern_exec.c ----------
src = read(EXEC)
orig_md5 = md5(EXEC)
A4 = """	proc_lock(p);
	proc_csflags_update(p, imgp->ip_csflags);
	proc_unlock(p);
"""
NEW4 = """	proc_lock(p);
	proc_csflags_update(p, imgp->ip_csflags);
	proc_unlock(p);

	/* S97 diag: flags handed to the new process right after exec */
	{
		static unsigned s97_ex_n;
		if (s97_ex_n < 8) {
			s97_ex_n++;
			IOLog("star_ex97: %s[%d] ip_csflags=0x%x\\n",
			    p->p_comm, proc_getpid(p), (unsigned)imgp->ip_csflags);
		}
	}
"""
if "star_ex97" not in src:
    backup(EXEC)
src = apply(src, A4, NEW4, "exec csflags diag log", "star_ex97")
write(EXEC, src)
print("kern_exec.c md5:", orig_md5, "->", md5(EXEC))
print("DONE")
