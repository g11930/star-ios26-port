#!/usr/bin/env python3
"""stage26-procdump.py -- a dump of every process and thread, with the user stack walked,
printed into the kernel log when the heartbeat asks for it.

Why: SpringBoard and backboardd are alive and silent.  Their os_log never runs, so nothing
tells us where they are.  The kernel can: for each thread it prints the saved pc/lr/sp/fp and
walks the frame-pointer chain through the task's own page tables (pmap_find_pa_nofault +
phystokv), which is a user backtrace without the target's cooperation.

Idempotent: re-running replaces the block it added.
"""
import re
import sys

TREE = "/root/star26/star-native"
KERN_PROC = TREE + "/bsd/kern/kern_proc.c"
LOADER_RETURN = TREE + "/osfmk/arm64/loader_return.c"

MARK_BEGIN = "/* ===== STARPD: process and thread dump, stage26 ===== */"
MARK_END = "/* ===== STARPD end ===== */"

INCLUDES = """
/* stage26: needed by the dump below */
#include <kern/task.h>
#include <kern/thread.h>
#include <arm/thread.h>
#include <arm/pmap/pmap.h>
"""

BLOCK = MARK_BEGIN + r"""
#define STARPD_MAXPROCS  72
#define STARPD_MAXTHREADS 10
#define STARPD_MAXFRAMES 20

extern pmap_t get_task_pmap(task_t);
extern pmap_paddr_t pmap_find_pa_nofault(pmap_t map, addr64_t va);
extern vm_map_address_t phystokv(pmap_paddr_t pa);

static boolean_t
star_uva_read(pmap_t pmap, uint64_t va, void *dst, size_t n)
{
	uint8_t *d = (uint8_t *)dst;

	while (n > 0) {
		uint64_t page = va & ~(uint64_t)0xfff;
		pmap_paddr_t pa = pmap_find_pa_nofault(pmap, page);
		size_t off = (size_t)(va - page);
		size_t chunk = 0x1000 - off;

		if (pa == 0) {
			return FALSE;
		}
		if (chunk > n) {
			chunk = n;
		}
		memcpy(d, (const void *)(phystokv(pa) + off), chunk);
		d += chunk;
		va += chunk;
		n -= chunk;
	}
	return TRUE;
}

static void
star_user_backtrace(pmap_t pmap, uint64_t pc, uint64_t lr, uint64_t fp)
{
	uint64_t frame[2];

	printf("STARPD    pc=%#llx lr=%#llx fp=%#llx\n",
	    (unsigned long long)pc, (unsigned long long)lr, (unsigned long long)fp);
	if (pmap == NULL) {
		return;
	}
	for (int i = 0; i < STARPD_MAXFRAMES; i++) {
		if (fp < 0x100000000ULL || (fp & 7) != 0) {
			break;
		}
		if (!star_uva_read(pmap, fp, frame, sizeof(frame))) {
			break;
		}
		printf("STARPD    #%d %#llx\n", i, (unsigned long long)frame[1]);
		if (frame[0] <= fp) {
			break;
		}
		fp = frame[0];
	}
}

void
star_procdump(const char *why)
{
	proc_t p;
	int nproc = 0;

	printf("STARPD === begin %s ===\n", why);
	proc_list_lock();
	for (p = LIST_FIRST(&allproc); p != NULL; p = LIST_NEXT(p, p_list)) {
		task_t task = proc_task(p);
		pmap_t pmap = NULL;
		thread_t th;
		int nthr = 0;

		printf("STARPD pid=%d stat=%d comm=%s\n",
		    p->p_pid, (int)p->p_stat, p->p_comm);
		if (++nproc >= STARPD_MAXPROCS) {
			break;
		}
		if (task == NULL) {
			continue;
		}
		task_reference(task);
		pmap = get_task_pmap(task);
		queue_iterate(&task->threads, th, thread_t, task_threads) {
			arm_saved_state_t *ss = get_user_regs(th);
			uint64_t pc = 0, lr = 0, fp = 0, sp = 0;

			if (ss != NULL) {
				pc = (uint64_t)get_saved_state_pc(ss);
				lr = (uint64_t)get_saved_state_lr(ss);
				fp = (uint64_t)get_saved_state_fp(ss);
				sp = (uint64_t)get_saved_state_sp(ss);
			}
			printf("STARPD  tid=%llx state=%d wait=%#llx sp=%#llx\n",
			    (unsigned long long)thread_tid(th), th->state,
			    (unsigned long long)th->wait_event, (unsigned long long)sp);
			if (pc != 0) {
				star_user_backtrace(pmap, pc, lr, fp);
			}
			if (++nthr >= STARPD_MAXTHREADS) {
				break;
			}
		}
		task_deallocate(task);
	}
	proc_list_unlock();
	printf("STARPD === end %s, %d procs ===\n", why, nproc);
}
""" + MARK_END + "\n"

CALL_SITE = """	if (loader_live.heartbeat == 30) {
		star_procdump("t300");
	}
	if (loader_live.heartbeat == 60) {
		star_procdump("t600");
	}
	if (++loader_live.heartbeat % MEMORY_REPORT_BEATS == 0) {"""


def patch_kern_proc():
    src = open(KERN_PROC).read()
    src = re.sub(re.escape(MARK_BEGIN) + r".*?" + re.escape(MARK_END) + r"\n", "", src, flags=re.S)
    if "/* stage26: needed by the dump below */" not in src:
        anchor = "#include <kern/backtrace.h>"
        if anchor not in src:
            raise SystemExit("kern_proc.c: anchor %r not found" % anchor)
        src = src.replace(anchor, anchor + "\n" + INCLUDES, 1)
    src = src.rstrip("\n") + "\n\n" + BLOCK
    open(KERN_PROC, "w").write(src)
    print("kern_proc.c: dump block installed (%d bytes of source)" % len(BLOCK))


def patch_loader_return():
    src = open(LOADER_RETURN).read()
    if "star_procdump(" in src:
        print("loader_return.c: call site already there")
        return
    anchor = "\tif (++loader_live.heartbeat % MEMORY_REPORT_BEATS == 0) {"
    if anchor not in src:
        raise SystemExit("loader_return.c: heartbeat anchor not found")
    src = src.replace(anchor, CALL_SITE, 1)
    decl = "extern void star_procdump(const char *why);\n"
    danchor = "#define MEMORY_REPORT_BEATS"
    idx = src.find(danchor)
    if idx < 0:
        raise SystemExit("loader_return.c: MEMORY_REPORT_BEATS not found")
    src = src[:idx] + decl + src[idx:]
    open(LOADER_RETURN, "w").write(src)
    print("loader_return.c: dumps at heartbeats 30 and 60 (300 s and 600 s)")


if __name__ == "__main__":
    patch_kern_proc()
    patch_loader_return()
    print("DONE (no device was touched)")
