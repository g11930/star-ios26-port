#!/usr/bin/env python3
"""stage24: publish apfs-preboot-uuid on IODeviceTree:/chosen.

libignition (inside launchd) looks the preboot volume up by asking the device tree
for apfs-preboot-uuid -- the same property IOGetApfsPrebootUUID() reads for the
kern.apfsprebootuuid sysctl.  Real iOS gets it from iBoot.  Our loader builds the
device tree without it, so the lookup fails and launchd falls back to the Darwin
Bootstrapper path, where keybagd then decides the system needs a recovery reboot.

The fix: as soon as an APFS container is mounted and names a preboot volume, ask
IOKit to put that UUID on /chosen.  The value is the same string the sysctl
reports, so userland sees one answer either way.
"""
import io
import os
import sys

ROOT = "/root/star26/star-native"
IOKIT = os.path.join(ROOT, "iokit/bsddev/IOKitBSDInit.cpp")
VFS = os.path.join(ROOT, "bsd/miscfs/apfs/apfs_vfsops.c")

MARK_IOKIT = "IOSetApfsPrebootUUID"
MARK_VFS = "STARPB"

IOKIT_ANCHOR = '''bool
IOGetApfsPrebootUUID(char *uuid)
'''

IOKIT_NEW = '''/*
 * The other half of IOGetApfsPrebootUUID(): what iBoot would have put in the device
 * tree, written once the kernel has found a preboot volume by itself.  libignition
 * asks the device tree, not the sysctl, so a boot without this property cannot
 * finish ignition (launchd then falls back to the Darwin Bootstrapper, whose keybag
 * task refuses to open a system bag and reboots).
 */
extern "C" void
IOSetApfsPrebootUUID(const char *uuid)
{
\tIORegistryEntry *entry;
\tOSData *data;

\tif (uuid == NULL || uuid[0] == '\\0') {
\t\treturn;
\t}
\tif ((entry = IORegistryEntry::fromPath("/chosen", gIODTPlane)) == NULL) {
\t\treturn;
\t}
\tif ((data = OSData::withBytes(uuid, (unsigned int)strlen(uuid) + 1)) != NULL) {
\t\tentry->setProperty("apfs-preboot-uuid", data);
\t\tdata->release();
\t}
\tentry->release();
}

bool
IOGetApfsPrebootUUID(char *uuid)
'''

VFS_ANCHOR = '''\tapfs_the_mount = am;
\tam->am_rdev = vnode_specrdev(devvp);'''

VFS_NEW = '''\tapfs_the_mount = am;
\tam->am_rdev = vnode_specrdev(devvp);
\t/*
\t * Give libignition the property iBoot would have handed down, so ignition can find
\t * the preboot volume instead of falling back to the Darwin Bootstrapper.  Once is
\t * enough: the answer is a property of the container, not of this mount.
\t */
\t{
\t\tstatic int published;
\t\tchar pb[64];

\t\tif (!published && apfs_preboot_uuid_scan(pb, sizeof(pb)) == 0) {
\t\t\tpublished = 1;
\t\t\tIOSetApfsPrebootUUID(pb);
\t\t\tloader_log_line("STARPB: apfs-preboot-uuid on /chosen\\n");
\t\t}
\t}'''

VFS_DECL = '''
extern void IOSetApfsPrebootUUID(const char *uuid);
extern int apfs_preboot_uuid_scan(char *out, size_t outlen);
extern void loader_log_line(const char *line);
'''


def read(p):
    with io.open(p, "r", encoding="utf-8", errors="surrogateescape") as f:
        return f.read()


def write(p, s):
    with io.open(p, "w", encoding="utf-8", errors="surrogateescape", newline="") as f:
        f.write(s)


def main(apply):
    c = read(IOKIT)
    v = read(VFS)
    changes = []

    if MARK_IOKIT not in c:
        if IOKIT_ANCHOR not in c:
            sys.exit("IOKitBSDInit.cpp: IOGetApfsPrebootUUID anchor not found")
        c = c.replace(IOKIT_ANCHOR, IOKIT_NEW, 1)
        if "#include <libkern/c++/OSData.h>" not in c:
            marker = "#include <libkern/c++/OSAllocation.h>"
            if marker not in c:
                sys.exit("IOKitBSDInit.cpp: no place found for the OSData include")
            c = c.replace(marker, marker + "\n#include <libkern/c++/OSData.h>", 1)
        changes.append("IOKitBSDInit.cpp: IOSetApfsPrebootUUID()")

    if MARK_VFS not in v:
        if VFS_ANCHOR not in v:
            sys.exit("apfs_vfsops.c: mount tail anchor not found")
        v = v.replace(VFS_ANCHOR, VFS_NEW, 1)
        needed = [d for d in ("extern void IOSetApfsPrebootUUID(const char *uuid);",
                              "extern int apfs_preboot_uuid_scan(char *out, size_t outlen);")
                  if d not in v]
        if needed:
            marker = "extern void loader_log_line(const char *line);"
            block = "\n".join(needed) + "\n"
            if marker in v:
                v = v.replace(marker, marker + "\n" + block, 1)
            else:
                marker = "#include <pexpert/pexpert.h>"
                if marker not in v:
                    sys.exit("apfs_vfsops.c: no anchor for the declarations")
                v = v.replace(marker, marker + "\n\n" + block, 1)
        changes.append("apfs_vfsops.c: publish the preboot uuid on /chosen")

    if not changes:
        print("stage24: already applied")
        return

    print("stage24: " + "; ".join(changes))
    if apply:
        write(IOKIT, c)
        write(VFS, v)
        print("stage24: WRITTEN")
    else:
        print("stage24: dry run, nothing written")


if __name__ == "__main__":
    main("--check" not in sys.argv)
