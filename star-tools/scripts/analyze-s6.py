#!/usr/bin/env python3
"""Decode the s6 staged blobs (kernel log / framebuffer dump).

s6 should be the first run where the kernel actually hands control back, so
s6-final.bin is expected to contain the REAL full kernel log of this boot.
The markers below are exactly the stage-1/3/4 additions plus the standard
XNU banners, so a hit proves the code ran and a miss proves it did not.
"""
import re
import sys
import os

MARKERS = [
    b"Darwin Kernel Version",
    b"StarDisk: published",
    b"star: UFS LUN 0 measured",
    b"star: RTC from persist",
    b"star_display: handoff base=",
    b"star_display: boot-args video MATCHES",
    b"star_display: owner=loader",
    b"star: milestone ",
    b"star_display: READ-ONLY survey",
    b"bsd_init: done",
    b"initproc failed",
    b"ufs: native",
    b"apfs: volume",
    b"ramfs: loaded /private/var",
    b"com.apple.xpc.launchd",
    b"panic",
    b"FAULT:",
    b"Invalid kernel stack",
    b"== KERNEL LOG",
    b"OEM STOP",
    b"returned",
]


def strings(data, minlen=6):
    return [(m.start(), m.group().decode("ascii", "replace"))
            for m in re.finditer(rb"[ -~]{%d,}" % minlen, data)]


def main():
    for path in sys.argv[1:]:
        if not os.path.exists(path):
            print("%-24s MISSING" % path)
            continue
        d = open(path, "rb").read()
        print("\n=== %s  %d bytes  nonzero=%d ===" %
              (os.path.basename(path), len(d), sum(1 for b in d if b)))
        hits = {}
        for k in MARKERS:
            n = d.count(k)
            if n:
                hits[k] = (n, [i for i in range(len(d)) if d.startswith(k, i)][:4])
        for k in MARKERS:
            if k in hits:
                n, pos = hits[k]
                print("  HIT  %-42s x%-3d %s" % (k.decode(), n, pos))
        print("  --- %d markers hit ---" % len(hits))
        lines = strings(d)
        print("  first 60 printable runs:")
        for off, t in lines[:60]:
            print("    %7d  %s" % (off, t[:170]))


if __name__ == "__main__":
    main()
