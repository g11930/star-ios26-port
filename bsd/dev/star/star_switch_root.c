/*
 * star_switch_root.c -- kern.annibale_switch_root for star / SM8350.
 *
 * The kernel starts on the RAM image (md0).  Its init mounts the iOS root
 * volume read only, prepares /annibale, /private/preboot and the bind mounts
 * the system needs, and then asks for the last step -- the same contract the
 * annibale port uses, because the userland in the boot image is the same
 * (userland/src/init.c: sysctlbyname("kern.annibale_switch_root", NULL, NULL,
 * "/flash private/preboot", 22)).
 *
 *   "INCOMING OUTGOING": the volume mounted on INCOMING becomes the root, and
 *   what was the root until now is mounted on OUTGOING inside it (a path
 *   without a leading slash, which must be a directory there -- on the iOS
 *   volume, a synthetic one).  devfs stays on /dev (vfs_switch_root() keeps it
 *   there).  Process 1 only, once.
 *
 * Kept apart from the other star files on purpose: it is the one place in
 * this tree that changes where the root is, so it stays easy to find and to
 * read.  Nothing else calls it.
 */
#include <sys/param.h>
#include <sys/systm.h>
#include <sys/errno.h>
#include <sys/kauth.h>
#include <sys/proc.h>
#include <sys/proc_internal.h>
#include <sys/mount.h>
#include <sys/mount_internal.h>
#include <sys/sysctl.h>
#include <sys/stat.h>
#include <sys/ucred.h>
#include <sys/vnode.h>
#include <sys/vnode_internal.h>
#include <libkern/libkern.h>
#include <mach/mach_types.h>

static int annibale_root_switched;

static int
annibale_sysctl_switch_root SYSCTL_HANDLER_ARGS
{
#pragma unused(oidp, arg1, arg2)
	char buf[512], *outgoing;
	int error;

	if (req->newptr == USER_ADDR_NULL) {
		return SYSCTL_OUT(req, annibale_root_switched ? "1" : "0", 2);
	}
	if (proc_getpid(current_proc()) != 1 || suser(kauth_cred_get(), NULL) != 0) {
		return EPERM;
	}
	if (annibale_root_switched) {
		return EBUSY;
	}
	if (req->newlen == 0 || req->newlen >= sizeof(buf)) {
		return EINVAL;
	}
	error = SYSCTL_IN(req, buf, req->newlen);
	if (error) {
		return error;
	}
	buf[req->newlen] = '\0';
	outgoing = strchr(buf, ' ');
	if (outgoing == NULL || buf[0] != '/') {
		return EINVAL;
	}
	*outgoing++ = '\0';
	error = vfs_switch_root(buf, outgoing, 0);
	printf("star: %s is the root now, the one before it on /%s: %d\n", buf, outgoing, error);
	if (error == 0) {
		vnode_t rootvp = NULLVP;
		annibale_root_switched = 1;
		if (vnode_lookup("/", 0, &rootvp, vfs_context_kernel()) == 0 && rootvp != NULLVP) {
			mount_t rmp = vnode_mount(rootvp);
			if (rmp != NULL) {
				strlcpy(vfs_statfs(rmp)->f_fstypename, "apfs",
				    sizeof(vfs_statfs(rmp)->f_fstypename));
				strlcpy(vfs_statfs(rmp)->f_mntfromname, "/dev/disk1s1",
				    sizeof(vfs_statfs(rmp)->f_mntfromname));
			}
			vnode_put(rootvp);
		}
	}
	return error;
}

SYSCTL_PROC(_kern, OID_AUTO, annibale_switch_root, CTLTYPE_STRING | CTLFLAG_RW | CTLFLAG_LOCKED,
    NULL, 0, annibale_sysctl_switch_root, "A",
    "write \"INCOMING OUTGOING\": the volume on INCOMING becomes the root (process 1, once)");
