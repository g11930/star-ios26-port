#!/usr/bin/env python3
# s98: 纯诊断（零行为变更）
#  1) star_msgprobe: 新增 star_tdump=1 -> 每目标只跑 annibale_thread_dump，
#     跳过 waitq_owner / turnstile 等有 zid=22 解引用风险的路径
#  2) IOAcceleratorES: 打 registerService 返回值 / RegistryEntryID / 是否在 gIOServicePlane
import hashlib, os, sys

ROOT = "/root/star26/star-native"
PROBE = os.path.join(ROOT, "bsd/dev/star/star_msgprobe.c")
FBINC = os.path.join(ROOT, "iokit/Kernel/MiniFramebufferUserClient.inc")

def read(p): return open(p, "rb").read().decode("utf-8")
def write(p, s): open(p, "wb").write(s.encode("utf-8"))
def md5(p): return hashlib.md5(open(p, "rb").read()).hexdigest()
def backup(p):
    b = p + ".s98-pre.bak"
    if not os.path.exists(b):
        open(b, "wb").write(open(p, "rb").read())
        print("backup ->", b)

def patch(path, pairs):
    s = read(path); m0 = md5(path)
    for name, anchor, new, marker in pairs:
        if marker in s:
            print(f"[skip] {name}")
            continue
        if s.count(anchor) != 1:
            sys.exit(f"[FATAL] {name}: anchor count={s.count(anchor)}")
        backup(path)
        s = s.replace(anchor, new)
        print(f"[ok] {name}")
    write(path, s)
    print(f"{os.path.basename(path)} md5: {m0} -> {md5(path)}")

# ---- star_msgprobe.c ----
A1 = """static const char *const star_msgprobe_targets[] = {
"""
N1 = """/* s98: tdump-only mode -- run annibale_thread_dump for each target and skip
 * the waitq/turnstile surveys (whose zid=22 dereference panicked in s82). */
static int star_tdump_only = 0;

static const char *const star_msgprobe_targets[] = {
"""

A2 = """				annibale_thread_dump(
				    (task_t)found[i].task, pp->p_pid,
				    exec_base, exec_image);
			}
		}
"""
N2 = """				annibale_thread_dump(
				    (task_t)found[i].task, pp->p_pid,
				    exec_base, exec_image);
			}
		}
		if (star_tdump_only) {
			continue;
		}
"""

A3 = """	if (!PE_parse_boot_argn("star_msgprobe", &ask, sizeof(ask)) || ask == 0) {
		return;
	}
"""
N3 = """	if (!PE_parse_boot_argn("star_msgprobe", &ask, sizeof(ask)) || ask == 0) {
		return;
	}
	(void)PE_parse_boot_argn("star_tdump", &star_tdump_only,
	    sizeof(star_tdump_only));
"""

# ---- MiniFramebufferUserClient.inc ----
A4 = """		accelerator->registerService();
		IOLog("IOAcceleratorES: published metal=%u metal_native=%u\\n",
		    metal, metal_native);
"""
N4 = """		bool reg = accelerator->registerService();
		IOLog("IOAcceleratorES: published metal=%u metal_native=%u reg=%d "
		    "entryID=0x%llx inPlane=%d name=%s\\n",
		    metal, metal_native, reg ? 1 : 0,
		    (unsigned long long)accelerator->getRegistryEntryID(),
		    accelerator->isInPlane(gIOServicePlane) ? 1 : 0,
		    accelerator->getName());
"""

patch(PROBE, [("tdump flag", A1, N1, "star_tdump_only"),
              ("tdump skip", A2, N2, "if (star_tdump_only)"),
              ("tdump bootarg", A3, N3, '"star_tdump"')])
patch(FBINC, [("accelerator reg diag", A4, N4, "inPlane=%d name=%s")])
print("DONE")
