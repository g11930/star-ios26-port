#!/usr/bin/env python3
"""
s74b: fix the s74 syscall-stub decoder.

Problems in s74:
1. The MOV Rd check tested bits[9:5] (imm16 low bits) instead of bits[4:0]
   (the real Rd) -- sc=368 for launchd T#0 only matched by coincidence
   (368 & 0x1f == 16).  The decoded VALUE was still correct (imm16 = 368
   = workq_kernreturn).
2. Only the 64-bit MOVZ/MOVN forms (0xD2800000/0x92800000) were matched;
   32-bit mov w16 forms (0x52800000/0x12800000) were not.
3. Mismatches printed nothing about the memory actually seen, so the
   mach_msg2 stub failures were undiagnosable.

Fix: read 16 bytes ending at pc (retry 8 at pc-8 on cross-page failure),
scan the window for [mov x/w16] followed by [svc #0x80] with the REAL Rd
check, and on no-match dump the four raw words into the log.
Signature gains a raw[] out param.  Read-only, idempotent, backups, anchors.
Usage: python3 apply-syscallprobe2.py [--check]
"""
import os
import shutil
import sys

K = "/root/star26/star-native/osfmk/kern/star_msgprobe_k.c"
B = "/root/star26/star-native/bsd/dev/star/star_msgprobe.c"
CHECK = "--check" in sys.argv

K_FUNC_OLD = '''int
star_msgprobe_syscall(void *vtask, uint64_t pc, int64_t *sc)
{
\ttask_t task = (task_t)vtask;
\tvm_map_t map;
\tvm_map_copy_t copy;
\tvm_offset_t kaddr = 0;
\tuint64_t addr;
\tuint32_t words[2];
\tkern_return_t kr;

\t*sc = 0;
\tif (task == NULL || pc < 8 || (pc & 3) != 0) {
\t\treturn -1;
\t}
\tmap = get_task_map(task);
\taddr = (pc - 8) & ~3ull;
\tkr = vm_map_copyin(map, (vm_offset_t)addr, 8, FALSE, &copy);
\tif (kr != KERN_SUCCESS) {
\t\treturn -1;
\t}
\tkr = vm_map_copyout(kernel_map, &kaddr, copy);
\tif (kr != KERN_SUCCESS) {
\t\tvm_map_copy_discard(copy);
\t\treturn -1;
\t}
\tmemcpy(words, (const void *)(uintptr_t)kaddr, sizeof(words));
\tkmem_free(kernel_map, kaddr, PAGE_SIZE_64);

\tif (words[1] == 0xD4001001u) {
\t\t/* svc #0x80 seen: decode the mov x16 that precedes it */
\t\tif ((words[0] & 0xFFE00000u) == 0xD2800000u &&
\t\t    ((words[0] >> 5) & 0x1Fu) == 16) {
\t\t\t*sc = (int64_t)((words[0] >> 5) & 0xFFFFu);
\t\t\treturn 0;
\t\t}
\t\tif ((words[0] & 0xFFE00000u) == 0x92800000u &&
\t\t    ((words[0] >> 5) & 0x1Fu) == 16) {
\t\t\t*sc = -(int64_t)((words[0] >> 5) & 0xFFFFu);
\t\t\treturn 0;
\t\t}
\t}
\treturn -2;
}'''

K_FUNC_NEW = '''int
star_msgprobe_syscall(void *vtask, uint64_t pc, int64_t *sc, uint32_t *raw)
{
\ttask_t task = (task_t)vtask;
\tvm_map_t map;
\tvm_map_copy_t copy;
\tvm_offset_t kaddr = 0;
\tuint64_t addr;
\tuint32_t words[4];
\tuint32_t len = 16;
\tkern_return_t kr;
\tint i;

\t*sc = 0;
\traw[0] = raw[1] = raw[2] = raw[3] = 0;
\tif (task == NULL || pc < 16 || (pc & 3) != 0) {
\t\treturn -1;
\t}
\tmap = get_task_map(task);
\taddr = (pc - 16) & ~3ull;
\tif ((addr & 0xFFF) > 0xFFC) {
\t\t/* 16 bytes would straddle two pages; use 8 */
\t\taddr = (pc - 8) & ~3ull;
\t\tlen = 8;
\t}
\tkr = vm_map_copyin(map, (vm_offset_t)addr, len, FALSE, &copy);
\tif (kr != KERN_SUCCESS) {
\t\treturn -1;
\t}
\tkr = vm_map_copyout(kernel_map, &kaddr, copy);
\tif (kr != KERN_SUCCESS) {
\t\tvm_map_copy_discard(copy);
\t\treturn -1;
\t}
\tmemcpy(words, (const void *)(uintptr_t)kaddr, len);
\tkmem_free(kernel_map, kaddr, PAGE_SIZE_64);
\traw[0] = words[0];
\traw[1] = words[1];
\traw[2] = words[2];
\traw[3] = words[3];

\t/* scan for [mov x/w16] followed by [svc #0x80]; the saved user pc
\t * sits right after the svc of the stub. */
\tfor (i = (int)(len / 4) - 2; i >= 0; i--) {
\t\tuint32_t mv = words[i];
\t\tuint32_t sv = words[i + 1];
\t\tint64_t imm;

\t\tif (sv != 0xD4001001u || (mv & 0x1Fu) != 16) {
\t\t\tcontinue;
\t\t}
\t\tswitch (mv & 0xFFE00000u) {
\t\tcase 0xD2800000u:           /* movz x16, #imm */
\t\tcase 0x52800000u:           /* movz w16, #imm */
\t\t\timm = (int64_t)((mv >> 5) & 0xFFFFu);
\t\t\t*sc = imm;
\t\t\treturn 0;
\t\tcase 0x92800000u:           /* movn x16, #imm */
\t\tcase 0x12800000u:           /* movn w16, #imm */
\t\t\timm = (int64_t)((mv >> 5) & 0xFFFFu);
\t\t\t*sc = -imm;
\t\t\treturn 0;
\t\t}
\t}
\treturn -2;
}'''

B_EXTERN_OLD = "extern int star_msgprobe_syscall(void *task, uint64_t pc, int64_t *sc);"
B_EXTERN_NEW = "extern int star_msgprobe_syscall(void *task, uint64_t pc, int64_t *sc, uint32_t *raw);"

B_CALL_OLD = '''\t\t\t\tint64_t sc = 0;
\t\t\t\tint skr = star_msgprobe_syscall(
\t\t\t\t    found[i].task, regs[3], &sc);

\t\t\t\tif (skr == 0) {
\t\t\t\t\tIOLog("StarMsgProbe:     sc=%lld",
\t\t\t\t\t    sc);
\t\t\t\t} else {
\t\t\t\t\tIOLog("StarMsgProbe:     sc=? kr=%d",
\t\t\t\t\t    skr);
\t\t\t\t}'''

B_CALL_NEW = '''\t\t\t\tint64_t sc = 0;
\t\t\t\tuint32_t raw[4];
\t\t\t\tint skr = star_msgprobe_syscall(
\t\t\t\t    found[i].task, regs[3], &sc, raw);

\t\t\t\tif (skr == 0) {
\t\t\t\t\tIOLog("StarMsgProbe:     sc=%lld",
\t\t\t\t\t    sc);
\t\t\t\t} else {
\t\t\t\t\tIOLog("StarMsgProbe:     sc=? kr=%d "
\t\t\t\t\t    "w=%x,%x,%x,%x",
\t\t\t\t\t    skr, raw[0], raw[1], raw[2],
\t\t\t\t\t    raw[3]);
\t\t\t\t}'''

PATCHES = [
    (K, "k-func", K_FUNC_OLD, K_FUNC_NEW),
    (B, "b-extern", B_EXTERN_OLD, B_EXTERN_NEW),
    (B, "b-call", B_CALL_OLD, B_CALL_NEW),
]

SKIP_TOKEN = {
    "k-func":   "raw[3] = words[3]",
    "b-extern": "uint32_t *raw",
    "b-call":   "w=%x,%x,%x,%x",
}


def main():
    print(f"mode={'CHECK' if CHECK else 'APPLY'}")
    for path, label, old, new in PATCHES:
        with open(path, "r", encoding="utf-8") as f:
            data = f.read()
        if SKIP_TOKEN[label] in data:
            print(f"[skip] {label}: already applied")
            continue
        cnt = data.count(old)
        if cnt != 1:
            print(f"[FAIL] {label}: anchor count={cnt} (need 1)")
            sys.exit(2)
        if CHECK:
            print(f"[check OK] {label}")
            continue
        bak = path + ".s74b.bak"
        if not os.path.exists(bak):
            shutil.copy2(path, bak)
            print(f"[backup] {bak}")
        data = data.replace(old, new, 1)
        with open(path, "w", encoding="utf-8") as f:
            f.write(data)
        print(f"[patched] {label}")
    print("done")


if __name__ == "__main__":
    main()
