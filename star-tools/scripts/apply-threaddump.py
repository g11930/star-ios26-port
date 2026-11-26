#!/usr/bin/env python3
"""
s77: port annibale's kern.annibale thread_dump tool (B2) and hook it into
star_msgprobe so every pass prints, per target process (launchd pid 1,
backboardd, SpringBoard), one line per thread (tid/state/wait_event/pri/
user pc + slide + exec image) plus a full user-mode backtrace per thread.

Sources: /root/ref2/annibale-kernel (k90-port, files/ layout).
 - osfmk half  copied VERBATIM:  xnu/files/osfmk/kern/annibale_threads.c
   (deps all present in our tree: vm_map_read_user, backtrace_user,
   annibale_tl (StarDisplayCompat.cpp, extern "C"), task->machine.upcb).
 - bsd half    rewritten slim:   bsd/dev/star/annibale_threads.c -- only the
   region/exec-image helpers (fill_procregioninfo*, bsdtask_info.h); no
   sysctl, no touch_lat watcher (our hook calls the dump directly).
 - star_msgprobe.c gains externs + the dump call per target.
 - conf: osfmk/conf/files += osfmk/kern/annibale_threads.c,
         bsd/conf/files  += bsd/dev/star/annibale_threads.c.

Read-only diagnostics; nothing enabled unless star_msgprobe=1 already runs.
Idempotent, backed up, strict anchors.  Usage: apply-threaddump.py [--check]
"""
import os
import shutil
import sys

ROOT = "/root/star26/star-native"
SRC = "/root/ref2/annibale-kernel/xnu/files"
CHECK = "--check" in sys.argv

K = ROOT + "/osfmk/kern/star_msgprobe_k.c"
B = ROOT + "/bsd/dev/star/star_msgprobe.c"

K_O = ROOT + "/osfmk/kern/annibale_threads.c"
B_O = ROOT + "/bsd/dev/star/annibale_threads.c"

BSD_SLIM = '''/*
 * bsd half of kern.annibale thread_dump, ported (s77) from the K90 tree's
 * bsd/dev/annibale/annibale_threads.c -- only the region/exec-image helpers.
 * The dump itself lives in osfmk/kern/annibale_threads.c (struct task is
 * MACH_KERNEL_PRIVATE); star_msgprobe.c calls it for each target process.
 * fill_procregioninfo* are declared in bsd/sys/bsdtask_info.h.
 */

#include <sys/param.h>
#include <sys/systm.h>
#include <sys/proc.h>
#include <sys/vnode.h>
#include <mach/mach_types.h>
#include <kern/task.h>
#include <sys/bsdtask_info.h>

#define ANNIBALE_EXEC_IMAGE_PROBES 64

void annibale_thread_dump(task_t task, int pid, uint64_t exec_base,
    const char *exec_image);

/*
 * fill_procregioninfo* hands the vnode over as a bare address; the vid is
 * what makes taking a reference here safe.  Leaves `name` non-empty
 * ("-" when there is no name) so printed lines keep their field count.
 */
static bool
annibale_vnode_name(uintptr_t vnodeaddr, uint32_t vid, char *name,
    uint32_t namelen)
{
	vnode_t vp = (vnode_t)(uintptr_t)vnodeaddr;
	const char *cached;
	bool have = false;

	strlcpy(name, "-", namelen);
	if (vnodeaddr == 0) {
		return false;
	}
	if (vnode_getwithvid(vp, vid) != 0) {
		return false;
	}
	cached = vnode_getname(vp);
	if (cached != NULL) {
		strlcpy(name, cached, namelen);
		vnode_putname(cached);
		have = true;
	}
	vnode_put(vp);
	return have;
}

/*
 * The image backing `addr`, or 0 when no map entry covers it.  The
 * containment check is done here rather than trusting fill_procregioninfo
 * to report the covering region.
 */
int
annibale_task_region_image(task_t task, uint64_t addr, char *name,
    uint32_t namelen, uint64_t *start, uint64_t *end)
{
	struct proc_regioninfo_internal info;
	uintptr_t vnodeaddr = 0;
	uint32_t vid = 0;

	memset(&info, 0, sizeof(info));
	if (fill_procregioninfo(task, addr, &info, &vnodeaddr, &vid) == 0) {
		strlcpy(name, "-", namelen);
		return 0;
	}
	if (addr < info.pri_address || addr >= info.pri_address + info.pri_size) {
		strlcpy(name, "-", namelen);
		return 0;
	}

	if (start != NULL) {
		*start = info.pri_address;
	}
	if (end != NULL) {
		*end = info.pri_address + info.pri_size;
	}
	annibale_vnode_name(vnodeaddr, vid, name, namelen);
	return 1;
}

/*
 * Start of the first vnode-backed executable region (the main binary's
 * __TEXT on iOS) and its file name.  0 when the task maps none.
 */
uint64_t
annibale_task_exec_image(task_t task, char *name, uint32_t namelen)
{
	uint64_t addr = 0;
	int probes;

	strlcpy(name, "-", namelen);
	for (probes = 0; probes < ANNIBALE_EXEC_IMAGE_PROBES; probes++) {
		struct proc_regioninfo_internal info;
		uintptr_t vnodeaddr = 0;
		uint32_t vid = 0;
		uint64_t next;

		memset(&info, 0, sizeof(info));
		if (fill_procregioninfo_onlymappedvnodes(task, addr, &info,
		    &vnodeaddr, &vid) == 0) {
			return 0;
		}
		next = info.pri_address + info.pri_size;
		if (info.pri_protection & VM_PROT_EXECUTE) {
			annibale_vnode_name(vnodeaddr, vid, name, namelen);
			return info.pri_address;
		}
		if (next <= addr) {
			return 0;
		}
		addr = next;
	}
	return 0;
}
'''

B_EXTERN_OLD = "extern int star_msgprobe_syscall(void *task, uint64_t pc, int64_t *sc, uint32_t *raw);"
B_EXTERN_NEW = B_EXTERN_OLD + '''
extern int annibale_task_exec_image(void *task, char *name, uint32_t namelen);
extern void annibale_thread_dump(void *task, int pid, uint64_t exec_base,
    const char *exec_image);'''

B_HOOK_OLD = '''\t\tfor (int t = 0; t < n && printed < STAR_MSGPROBE_MAXLINES; t++) {'''
B_HOOK_NEW = '''\t\t/* s77: full per-thread user backtraces (annibale thread_dump).
\t\t * One dump per target, before the per-thread lines: the bt frames
\t\t * name the exact user-mode function each thread is parked in. */
\t\t{
\t\t\tproc_t pp = (proc_t)task_get_proc_raw(
\t\t\t    (task_t)found[i].task);

\t\t\tif (pp != NULL) {
\t\t\t\tchar exec_image[64];
\t\t\t\tuint64_t exec_base =
\t\t\t\t    annibale_task_exec_image(
\t\t\t\t    (task_t)found[i].task, exec_image,
\t\t\t\t    sizeof(exec_image));

\t\t\t\tannibale_thread_dump(
\t\t\t\t    (task_t)found[i].task, pp->p_pid,
\t\t\t\t    exec_base, exec_image);
\t\t\t}
\t\t}
\t\tfor (int t = 0; t < n && printed < STAR_MSGPROBE_MAXLINES; t++) {'''

CONF_O = ROOT + "/osfmk/conf/files"
CONF_B = ROOT + "/bsd/conf/files"

steps = []


def step_file_copy(src, dst, label):
    steps.append((label, src, dst, None, None, None))


def step_patch(path, label, old, new, token):
    steps.append((label, path, None, old, new, token))


step_file_copy(SRC + "/osfmk/kern/annibale_threads.c", K_O, "osfmk-copy")
step_file_copy(None, B_O, "bsd-slim")
step_patch(B_O, "bsd-slim-content", None, BSD_SLIM, "annibale_task_exec_image")
step_patch(B, "b-extern", B_EXTERN_OLD, B_EXTERN_NEW, "annibale_thread_dump")
step_patch(B, "b-hook", B_HOOK_OLD, B_HOOK_NEW, "annibale thread_dump")
step_patch(CONF_O, "conf-osfmk", "osfmk/kern/star_msgprobe_k.c\t\tstandard",
    "osfmk/kern/star_msgprobe_k.c\t\tstandard\n"
    "osfmk/kern/annibale_threads.c\t\tstandard",
    "annibale_threads.c")
step_patch(CONF_B, "conf-bsd", "bsd/dev/star/star_msgprobe.c\t\tstandard",
    "bsd/dev/star/star_msgprobe.c\t\tstandard\n"
    "bsd/dev/star/annibale_threads.c\tstandard",
    "annibale_threads.c")


def main():
    print(f"mode={'CHECK' if CHECK else 'APPLY'}")
    for label, src, dst, old, new, token in steps:
        if label == "osfmk-copy":
            if os.path.exists(dst):
                print(f"[skip] {label}: exists")
                continue
            if CHECK:
                print(f"[check OK] {label} (would copy {src})")
                continue
            shutil.copy2(src, dst)
            print(f"[copied] {dst}")
            continue
        if label == "bsd-slim":
            if os.path.exists(dst):
                print(f"[skip] {label}: exists")
                continue
            if CHECK:
                print(f"[check OK] {label} (would write {dst})")
                continue
            with open(dst, "w", encoding="utf-8") as f:
                f.write(BSD_SLIM)
            print(f"[written] {dst}")
            continue
        path = src
        with open(path, "r", encoding="utf-8") as f:
            data = f.read()
        if old is not None and token in data:
            print(f"[skip] {label}: already applied")
            continue
        if old is None:
            continue
        cnt = data.count(old)
        if cnt != 1:
            print(f"[FAIL] {label}: anchor count={cnt} (need 1)")
            sys.exit(2)
        if CHECK:
            print(f"[check OK] {label}")
            continue
        bak = path + ".s77.bak"
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
