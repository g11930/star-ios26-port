#!/usr/bin/env python3
"""Decode the s7 staged blobs: the kernel log, and the panel framebuffer.

s7 is the first run with the display/GPU ABI layer in the kernel, so besides
the usual boot markers this looks for the three services and for the first
frame reaching the panel:

  IOMobileFramebuffer / disp0 / IOCoreSurfaceRoot   the services exist
  AnnibaleGPU: stub service registered              the GPU path chose the stub
  MiniIOMobileFramebuffer: first frame              the panel got a frame

s7-screen.bin is `oem screenshot`: raw pixels of 0xEA600000, 1440x3200,
32 bits per pixel, row stride taken from the framebuffer geometry.
It is converted to PNG so the desktop (or the absence of it) is visible.
"""
import os
import re
import sys

MARKERS = [
    b"Darwin Kernel Version",
    b"IOSurface", b"IOCoreSurfaceRoot", b"disp0",
    b"AnnibaleGPU", b"stub service registered", b"AnnibaleGPU: stub",
    b"MiniIOMobileFramebuffer",
    b"star: brightness request refused",
    b"StarDisk: published",
    b"star_display: handoff base=",
    b"star: milestone ",
    b"bsd_init: done",
    b"initproc failed",
    b"ramfs: loaded",
    b"com.apple.xpc.launchd",
    b"WindowServer", b"backboardd", b"SpringBoard",
    b"panic", b"FAULT:",
]

WIDTH, HEIGHT = 1440, 3200


def strings(data, minlen=6):
    return [(m.start(), m.group().decode("ascii", "replace"))
            for m in re.finditer(rb"[ -~]{%d,}" % minlen, data)]


def report_log(path):
    d = open(path, "rb").read()
    print("\n=== %s  %d bytes  nonzero=%d ===" %
          (os.path.basename(path), len(d), sum(1 for b in d if b)))
    if len(d) == 0:
        print("  empty")
        return
    hit = 0
    for k in MARKERS:
        n = d.count(k)
        if n:
            hit += 1
            pos = [i for i in range(len(d)) if d.startswith(k, i)][:3]
            print("  HIT  %-36s x%-3d %s" % (k.decode(), n, pos))
    print("  --- %d markers hit ---" % hit)
    lines = strings(d)
    print("  first 40 printable runs:")
    for off, t in lines[:40]:
        print("    %7d  %s" % (off, t[:160]))


def convert_screen(path):
    if not os.path.exists(path) or os.path.getsize(path) < 1024:
        print("\n%s missing or empty -- no framebuffer dump this run" % path)
        return
    try:
        from PIL import Image
    except ImportError:
        print("\nPIL not available; raw framebuffer left at %s" % path)
        return
    d = open(path, "rb").read()
    need = WIDTH * HEIGHT * 4
    print("\n=== screen dump %d bytes (need %d for 1440x3200x4) ===" % (len(d), need))
    if len(d) < need:
        print("  short dump: the loader only stages what it has")
        return
    img = Image.frombytes("RGBA", (WIDTH, HEIGHT), d[:need], "raw", "BGRA")
    img = img.convert("RGB")
    out = path.replace(".bin", ".png")
    img.save(out)
    print("  written %s (%dx%d)" % (out, WIDTH, HEIGHT))
    # a quick "is anything on the panel" measure
    small = img.resize((144, 320))
    px = list(small.getdata())
    nonblack = sum(1 for r, g, b in px if r + g + b > 24)
    uniq = len(set(px))
    print("  non-black %.1f%% of samples, %d distinct colours" %
          (100.0 * nonblack / len(px), uniq))


def main():
    for path in sys.argv[1:]:
        if path.endswith(".bin") and "screen" in os.path.basename(path):
            convert_screen(path)
        elif path.endswith(".bin"):
            report_log(path)


if __name__ == "__main__":
    main()
