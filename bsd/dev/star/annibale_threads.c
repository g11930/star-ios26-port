/*
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
