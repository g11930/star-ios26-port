#!/usr/bin/env python3
"""stage23: serve vfs.generic.apfs.edt_fstab, the device table libignition reads.

libignition (inside launchd) looks the preboot volume up through the sysctl
vfs.generic.apfs.edt_fstab: an array of { device name, APFS role }.  Real iOS gets
it from the APFS kext; this tree's APFS port has no such sysctl, which is why
launchd stopped at "failed to lookup preboot".

Data source: StarDisk, which already knows every volume it publishes and the role
mask it read from the volume superblock.  StarDisk.cpp keeps a table and exports it
through a C function; apfs_vfsops.c serves that table.

Element layout is the guess { char dev_name[32]; u32 role; u32 flags; } = 40 bytes,
8 entries.  If libignition disagrees it prints "expected element size", which the
diagnostic log line below makes easy to read off the next boot.
"""
import io
import os
import sys

ROOT = "/root/star26/star-native"
DISK = os.path.join(ROOT, "iokit/Kernel/StarDisk.cpp")
VFS = os.path.join(ROOT, "bsd/miscfs/apfs/apfs_vfsops.c")

MARK_DISK = "StarDiskVolumeTable"
MARK_VFS = "sysctl_apfs_edt_fstab"

DISK_TABLE = '''
/*
 * The device table libignition reads through vfs.generic.apfs.edt_fstab: every
 * volume of the container, by the role its superblock carries.  Filled as the
 * volumes are published; bsd/miscfs/apfs/apfs_vfsops.c serves it verbatim.
 */
#define STAR_EDT_FSTAB_COUNT 8
#define STAR_EDT_DEVNAME_LEN 32

struct star_edt_fstab_entry {
\tchar     dev_name[STAR_EDT_DEVNAME_LEN];
\tuint32_t role;
\tuint32_t flags;
};

static struct star_edt_fstab_entry gStarEdt[STAR_EDT_FSTAB_COUNT];
static int gStarEdtCount;

/* C ABI for bsd/miscfs/apfs/apfs_vfsops.c */
extern "C" int
StarDiskVolumeTable(void * out, int max_entries)
{
\tstruct star_edt_fstab_entry * e = (struct star_edt_fstab_entry *)out;
\tint i, n = 0;

\tif (out == NULL || max_entries <= 0) {
\t\treturn gStarEdtCount;
\t}
\tfor (i = 0; i < gStarEdtCount && n < max_entries; i++) {
\t\te[n++] = gStarEdt[i];
\t}
\treturn n;
}

'''

DISK_RECORD_OLD = '''\tif (star_publish(vol, container, bsdname) != NULL) {
\t\tIOLog("StarDisk: published volume '%s' (%s, Role %s)\\n", bsdname, volname, role);
\t\treturn vol;
\t}'''

DISK_RECORD_NEW = '''\tif (star_publish(vol, container, bsdname) != NULL) {
\t\tIOLog("StarDisk: published volume '%s' (%s, Role %s)\\n", bsdname, volname, role);
\t\tif (gStarEdtCount < STAR_EDT_FSTAB_COUNT) {
\t\t\tstruct star_edt_fstab_entry * e = &gStarEdt[gStarEdtCount++];
\t\t\tstrlcpy(e->dev_name, bsdname, sizeof(e->dev_name));
\t\t\te->role = roleMask;
\t\t\te->flags = writable ? 1 : 0;
\t\t}
\t\treturn vol;
\t}'''

VFS_BLOCK = '''
/* ------------------------------------------------------------------ ignition */

/*
 * vfs.generic.apfs.edt_fstab: the device table libignition looks the boot's volumes
 * up in -- one entry per APFS volume, its BSD device name and the role out of its
 * superblock.  Apple's APFS kext serves this out of the device tree fstab; this port
 * has no such table in the tree, so the answer comes from what StarDisk published.
 *
 * The buffer is always the full table (STAR_EDT_FSTAB_COUNT entries), zero filled
 * past the volumes that exist: libignition checks the size it gets against the entry
 * size it knows and refuses a buffer that is not a whole number of entries.
 */
#define STAR_EDT_FSTAB_COUNT 8

struct star_edt_fstab_entry {
\tchar     dev_name[32];
\tuint32_t role;
\tuint32_t flags;
};

extern int StarDiskVolumeTable(void *out, int max_entries);
extern void loader_log_line(const char *line);

static int
sysctl_apfs_edt_fstab SYSCTL_HANDLER_ARGS
{
#pragma unused(oidp, arg1, arg2)
\tstatic int calls;
\tstruct star_edt_fstab_entry e[STAR_EDT_FSTAB_COUNT];
\tchar line[192];
\tint n, i, at;

\tmemset(e, 0, sizeof(e));
\tn = StarDiskVolumeTable(e, STAR_EDT_FSTAB_COUNT);
\tif (n < 0) {
\t\tn = 0;
\t}
\t/* The first few calls, on the loader's log ring: what we served, and how big. */
\tif (calls < 8) {
\t\tcalls++;
\t\tat = scnprintf(line, sizeof(line), "STAREDT total=%u n=%d",
\t\t    (unsigned)sizeof(e), n);
\t\tfor (i = 0; i < n && at < (int)sizeof(line) - 40; i++) {
\t\t\tat += scnprintf(line + at, sizeof(line) - at, " [%s r=%x]",
\t\t\t    e[i].dev_name, e[i].role);
\t\t}
\t\tat += scnprintf(line + at, sizeof(line) - at, "\\n");
\t\tloader_log_line(line);
\t}
\treturn SYSCTL_OUT(req, e, sizeof(e));
}

SYSCTL_NODE(_vfs_generic, OID_AUTO, apfs, CTLFLAG_RW | CTLFLAG_LOCKED, 0, "APFS");
SYSCTL_PROC(_vfs_generic_apfs, OID_AUTO, edt_fstab,
    CTLTYPE_OPAQUE | CTLFLAG_RD | CTLFLAG_LOCKED, 0, 0, sysctl_apfs_edt_fstab, "-",
    "the device table ignition reads: BSD device names by APFS volume role");

'''

VFS_ANCHOR = '''SYSCTL_PROC(_kern, OID_AUTO, apfs_stats, CTLTYPE_STRING | CTLFLAG_RW | CTLFLAG_LOCKED,
    0, 0, sysctl_apfs_stats, "A", "APFS: where the time goes; write to zero it");
'''


def read(p):
    with io.open(p, "r", encoding="utf-8", errors="surrogateescape") as f:
        return f.read()


def write(p, s):
    with io.open(p, "w", encoding="utf-8", errors="surrogateescape", newline="") as f:
        f.write(s)


def patch(apply):
    d = read(DISK)
    v = read(VFS)
    changes = []

    if MARK_DISK not in d:
        if DISK_RECORD_OLD not in d:
            sys.exit("StarDisk.cpp: publish block not found")
        d = d.replace(DISK_RECORD_OLD, DISK_RECORD_NEW, 1)
        anchor = "static StarDisk * gStarDisk;\n"
        if anchor not in d:
            sys.exit("StarDisk.cpp: gStarDisk anchor not found")
        d = d.replace(anchor, anchor + DISK_TABLE, 1)
        if "#include <libkern/libkern.h>" not in d:
            d = d.replace("#include <libkern/c++/OSString.h>",
                          "#include <libkern/c++/OSString.h>\n#include <libkern/libkern.h>", 1)
        changes.append("StarDisk.cpp: volume table + StarDiskVolumeTable()")

    if MARK_VFS not in v:
        if VFS_ANCHOR not in v:
            sys.exit("apfs_vfsops.c: apfs_stats anchor not found")
        v = v.replace(VFS_ANCHOR, VFS_ANCHOR + VFS_BLOCK, 1)
        if "SYSCTL_DECL(_vfs_generic);" not in v:
            v = v.replace("#include <sys/sysctl.h>",
                          "#include <sys/sysctl.h>\n\nSYSCTL_DECL(_vfs_generic);", 1)
        changes.append("apfs_vfsops.c: vfs.generic.apfs.edt_fstab")

    if not changes:
        print("stage23: already applied")
        return

    print("stage23: " + "; ".join(changes))
    if apply:
        write(DISK, d)
        write(VFS, v)
        print("stage23: WRITTEN")
    else:
        print("stage23: dry run, nothing written")


if __name__ == "__main__":
    check = "--check" in sys.argv
    patch(not check)
