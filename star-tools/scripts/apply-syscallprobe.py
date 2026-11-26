#!/usr/bin/env python3
"""
s74: decode the syscall a blocked thread is sitting in (B1 probe).

A thread that entered a syscall has its saved user pc right AFTER the
"svc #0x80" of the libsystem_kernel stub ("mov x16,#num; svc #0x80"), so
reading the two words before the pc and decoding them yields the stub
number: BSD syscalls are positive (bsd/kern/syscalls.master), mach traps
are negative (osfmk/kern/syscall_sw.c, assert(call_number<0), table index
= -x16, names in mach_syscall_name_table).

osfmk half gains star_msgprobe_syscall(): vm_map_copyin+copyout 8 bytes
at (pc-8)&~3 from the task's map, decode, kmem_free.  Read-only.
bsd half prints "sc=<num>" for every TH_WAIT thread of the targets.
Read-only, log-only, idempotent, backed up, strict anchors.
Usage: python3 apply-syscallprobe.py [--check]
"""
import os
import shutil
import sys

K = "/root/star26/star-native/osfmk/kern/star_msgprobe_k.c"
B = "/root/star26/star-native/bsd/dev/star/star_msgprobe.c"
CHECK = "--check" in sys.argv

K_INC_OLD = "#include <kern/zalloc_internal.h>"
K_INC_NEW = K_INC_OLD + "\n#include <vm/vm_map.h>\n#include <vm/vm_kern.h>"

K_TAIL = '''\t\tout[4] = (uint64_t)zone_id_for_element(wqlocal.wq_q,
\t\t    sizeof(struct waitq));
\t}
\treturn 0;
}'''

K_FUNC = '''

/*
 * s74: decode the syscall a blocked thread is sitting in.  A thread that
 * entered a syscall has its saved user pc right after the "svc #0x80" of
 * the libsystem_kernel stub ("mov x16, #num; svc #0x80"), so read the two
 * words before pc from the task's address space and extract the stub
 * number.  Read-only; the page is already resident (the thread executed
 * it), so no pager interaction is expected.
 *
 * Returns 0 with *sc = stub number (BSD syscalls positive, mach traps
 * negative -- cf. bsd_arm64.c: assert(call_number < 0); table index =
 * -call_number), -1 on copy failure/bad input, -2 on pattern mismatch.
 */
int
star_msgprobe_syscall(void *vtask, uint64_t pc, int64_t *sc)
{
	task_t task = (task_t)vtask;
	vm_map_t map;
	vm_map_copy_t copy;
	vm_offset_t kaddr = 0;
	uint64_t addr;
	uint32_t words[2];
	kern_return_t kr;

	*sc = 0;
	if (task == NULL || pc < 8 || (pc & 3) != 0) {
		return -1;
	}
	map = get_task_map(task);
	addr = (pc - 8) & ~3ull;
	kr = vm_map_copyin(map, (vm_offset_t)addr, 8, FALSE, &copy);
	if (kr != KERN_SUCCESS) {
		return -1;
	}
	kr = vm_map_copyout(kernel_map, &kaddr, copy);
	if (kr != KERN_SUCCESS) {
		vm_map_copy_discard(copy);
		return -1;
	}
	memcpy(words, (const void *)(uintptr_t)kaddr, sizeof(words));
	kmem_free(kernel_map, kaddr, PAGE_SIZE_64);

	if (words[1] == 0xD4001001u) {
		/* svc #0x80 seen: decode the mov x16 that precedes it */
		if ((words[0] & 0xFFE00000u) == 0xD2800000u &&
		    ((words[0] >> 5) & 0x1Fu) == 16) {
			*sc = (int64_t)((words[0] >> 5) & 0xFFFFu);
			return 0;
		}
		if ((words[0] & 0xFFE00000u) == 0x92800000u &&
		    ((words[0] >> 5) & 0x1Fu) == 16) {
			*sc = -(int64_t)((words[0] >> 5) & 0xFFFFu);
			return 0;
		}
	}
	return -2;
}'''

B_EXTERN_OLD = "extern int star_msgprobe_thread_diag(void *thread, uint64_t *out);"
B_EXTERN_NEW = B_EXTERN_OLD + '''
extern int star_msgprobe_syscall(void *task, uint64_t pc, int64_t *sc);'''

B_LOOP_OLD = '''\t\t\tif (star_msgprobe_wait_regs(thr[t], regs) != 0) {
\t\t\t\tregs[3] = 0;
\t\t\t\tregs[4] = 0;
\t\t\t}
\t\t\tx1 = regs[1];
\t\t\tx4 = regs[2];'''

B_LOOP_NEW = B_LOOP_OLD + '''

\t\t\t/* s74: name the syscall this waiting thread is parked
\t\t\t * in by decoding the stub before its saved user pc. */
\t\t\t{
\t\t\t\tint64_t sc = 0;
\t\t\t\tint skr = star_msgprobe_syscall(
\t\t\t\t    found[i].task, regs[3], &sc);

\t\t\t\tif (skr == 0) {
\t\t\t\t\tIOLog("StarMsgProbe:     sc=%lld",
\t\t\t\t\t    sc);
\t\t\t\t} else {
\t\t\t\t\tIOLog("StarMsgProbe:     sc=? kr=%d",
\t\t\t\t\t    skr);
\t\t\t\t}
\t\t\t}'''

PATCHES = [
    (K, "k-include", K_INC_OLD, K_INC_NEW),
    (K, "k-append",  K_TAIL,    K_TAIL + K_FUNC),
    (B, "b-extern",  B_EXTERN_OLD, B_EXTERN_NEW),
    (B, "b-call",    B_LOOP_OLD, B_LOOP_NEW),
]

SKIP_TOKEN = {
    "k-include": "<vm/vm_map.h>",
    "k-append":  "star_msgprobe_syscall",
    "b-extern":  "star_msgprobe_syscall",
    "b-call":    "sc=%lld",
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
        bak = path + ".s74.bak"
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
