#!/usr/bin/env python3
"""Analyse the s4 USB capture: live kernel logs and the raw panel framebuffer.

Usage: python3 analyze-s4.py [directory]   (default /mnt/c/ios26)
Writes PNG previews next to the raw dump so the -v kernel console can be read
without a camera.  Read-only with respect to the phone.
"""
import os
import re
import sys

DIR = sys.argv[1] if len(sys.argv) > 1 else "/mnt/c/ios26"
LOGS = ("s4-klog-1.bin", "s4-klog-2.bin", "s4-final.bin")

KEYS = (
    "== XNULOADER v3 ==", "== KERNEL LOG ==", "Darwin Kernel Version",
    "star: UFS LUN 0 measured", "star: RTC from persist",
    "StarDisk: published", "star_display: handoff", "star_display: boot-args video",
    "star_display: owner=loader", "star_display: READ-ONLY survey",
    "star_display: splash", "star: milestone", "ufs: native", "apfs:",
    "vfs_mountroot", "cannot mount root", "bsd_init", "initproc",
    "launchd", "loader_return_after expired", "FAULT:", "PANIC", "panic",
    "Invalid kernel stack", "== END OF LOG ==",
)


def printable(data):
    return [m.group().decode("ascii", "replace")
            for m in re.finditer(rb"[ -~]{6,}", data)]


def analyse_log(path):
    if not os.path.exists(path) or os.path.getsize(path) == 0:
        print("\n%s: MISSING / EMPTY" % os.path.basename(path))
        return
    d = open(path, "rb").read()
    end = d.find(b"== END OF LOG ==")
    cur = d[:end + len(b"== END OF LOG ==")] if end >= 0 else d
    lines = printable(cur)
    print("\n%s: %d bytes, current-run %d bytes, %d printable runs" %
          (os.path.basename(path), len(d), len(cur), len(lines)))
    print("  keyword counts:")
    for k in KEYS:
        n = sum(1 for ln in lines if k in ln)
        if n:
            print("    %-40s %d" % (k, n))
    print("  first 25 lines:")
    for ln in lines[:25]:
        print("    " + ln[:200])
    print("  last 45 lines:")
    for ln in lines[-45:]:
        print("    " + ln[:200])


def decode_screen(path):
    if not os.path.exists(path) or os.path.getsize(path) < 1000000:
        print("\n%s: MISSING / TOO SMALL" % os.path.basename(path))
        return
    from PIL import Image
    w, h, stride = 1440, 3200, 5760
    need = stride * h
    d = open(path, "rb").read()
    print("\n%s: %d bytes (expect %d)" % (os.path.basename(path), len(d), need))
    if len(d) < need:
        print("  truncated; padding with zeros")
        d = d + b"\0" * (need - len(d))
    # Channel order does not matter for reading white-on-black console text:
    # take the max of the three colour bytes as luminance.
    px = bytearray(w * h)
    for y in range(h):
        row = d[y * stride:(y + 1) * stride]
        for x in range(w):
            o = x * 4
            px[y * w + x] = max(row[o], row[o + 1], row[o + 2])
    img = Image.frombytes("L", (w, h), bytes(px))
    full = os.path.join(DIR, "s4-screen-full.png")
    img.save(full)
    print("  wrote %s (%d x %d)" % (full, w, h))
    small = img.resize((w // 2, h // 2))
    sp = os.path.join(DIR, "s4-screen-small.png")
    small.save(sp)
    print("  wrote %s (%d x %d)" % (sp, w // 2, h // 2))
    # The verbose console occupies the top of the panel; two crops for reading.
    for name, box in (("s4-screen-top.png", (0, 0, w, 1200)),
                      ("s4-screen-mid.png", (0, 1000, w, 2400))):
        cp = os.path.join(DIR, name)
        img.crop(box).save(cp)
        print("  wrote %s %s" % (cp, box))
    nz = sum(1 for v in px if v > 16)
    print("  pixels with luminance > 16: %d / %d (%.2f%%)" %
          (nz, w * h, 100.0 * nz / (w * h)))


def main():
    print("=== s4 capture analysis (%s) ===" % DIR)
    for name in LOGS:
        analyse_log(os.path.join(DIR, name))
    decode_screen(os.path.join(DIR, "s4-screen.bin"))


if __name__ == "__main__":
    main()
