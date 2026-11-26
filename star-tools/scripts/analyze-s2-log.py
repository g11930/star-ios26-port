#!/usr/bin/env python3
"""Extract the CURRENT boot's kernel log from the s2 logdump partition.

The logdump partition is 16 MiB but the loader only writes the current run's
log at the front; everything after the first `== END OF LOG ==` is stale data
from older boots (iOS16/K90 era).  Truncate there before drawing conclusions.
"""
import re
import sys

PATH = sys.argv[1] if len(sys.argv) > 1 else "/mnt/c/ios26/s2-logdump.bin"
d = open(PATH, "rb").read()
print("file: %s (%d bytes)" % (PATH, len(d)))

# Work on the current run only.
end = d.find(b"== END OF LOG ==")
cur = d[:end + len(b"== END OF LOG ==")] if end >= 0 else d
print("current boot log: %d bytes (END OF LOG at %d)" % (len(cur), end))

lines = [x.decode("ascii", "replace") for x in re.findall(rb"[ -~]{6,}", cur)]
print("printable lines: %d" % len(lines))

KEYS = [
    "== XNULOADER v3 ==", "display 1440 x 3200", "platform star",
    "KERNEL LOG", "FAULT:", "PANIC", "panic", "Invalid kernel stack",
    "Darwin Kernel Version", "bsd_init", "StarDisk: published",
    "star: UFS LUN 0 measured", "star: RTC from persist",
    "star_display: handoff", "star_display: READ-ONLY survey",
    "star_display: boot-args video", "star_display: splash",
    "star: milestone", "vfs_mountroot", "cannot mount root",
    "initproc", "launchd", "loader_return_after expired",
    "ufs: native", "apfs:", "ramfs:", "Mounting", "END OF LOG",
]
print("\n--- keyword counts (current boot only) ---")
for k in KEYS:
    n = sum(1 for ln in lines if k in ln)
    print("  %-36s %d" % (k, n))

print("\n--- last 90 lines of the current boot ---")
for ln in lines[-90:]:
    print("  " + ln)
