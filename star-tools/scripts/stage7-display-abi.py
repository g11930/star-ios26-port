#!/usr/bin/env python3
"""stage7: bring the display/GPU ABI layer from the K90 tree into star-native.

What this is and is not
------------------------
The K90 tree carries a full IOKit implementation of Apple's display protocol:

  MiniIOSurface.cpp + UserClient     IOSurface service (`IOCoreSurfaceRoot`)
  MiniIOMobileFramebuffer.cpp        class **IOMobileFramebuffer**, service `disp0`
  MiniFramebufferFlip/Pacing/Rows/DCS/Dim
  AnnibaleGPU.cpp                    class AnnibaleGPU (has a hardware-free stub)

Measured coupling to the annibale SoC (grep count of `annibale`):
  MiniIOSurface.cpp            0     <- pure Apple ABI
  MiniIOSurfaceUserClient.inc  0
  MiniFramebufferFlip.inc      0     (one splash constant)
  MiniFramebufferPacing/Dim/Rows/DCS   0
  MiniIOMobileFramebuffer.cpp 10     <- logging + one counter + one property
  AnnibaleGPU.cpp            118     <- real SM8750 driver, but it ships a stub

So this stage copies the ABI layer (which any iOS userland requires, on any
SoC) and keeps the hardware-facing code OFF:

  * fb_flip / fb_dim / fb_dcs stay at their defaults (0).  flip_start() then
    returns on its first line, before ml_io_map(0x0ae00000): the star kernel
    never touches the MDSS/DPU, never flips, never reads a vsync.  The
    presenter writes each frame straight into the boot framebuffer at
    0xEA600000, which is exactly star's single-buffer model.
  * FLIP_SPLASH_PHYS is corrected to star's cont_splash_region anyway, so a
    future fb_flip=2 experiment starts from the right address instead of
    K90's 0xfc800000.
  * AnnibaleGPU runs its own stub path (AnnibaleGPUStartStub): the service
    registers, a drawable is the process's own memory, no register access.

The two annibale symbols the copied code still references are provided by
star_platform_stubs.c as compatibility shims, so none of the 3.3k copied
lines has to be rewritten.
"""
import os
import shutil
import sys

SRC = "/root/star26/kbuild/xnu-12377.121.6/iokit/Kernel"
DST = "/root/star26/star-native/iokit/Kernel"

FILES = [
    "MiniDrivers.h",
    "MiniIOSurface.cpp",
    "MiniIOSurface.h",
    "MiniIOSurfaceABI.h",
    "MiniIOSurfaceABI.inc",
    "MiniIOSurfaceUserClient.inc",
    "MiniIOSurfaceValues.inc",
    "MiniIOMobileFramebuffer.cpp",
    "MiniFramebufferScale.h",
    "MiniFramebufferSwap.h",
    "MiniFramebufferFlip.inc",
    "MiniFramebufferPacing.inc",
    "MiniFramebufferRows.inc",
    "MiniFramebufferDCS.inc",
    "MiniFramebufferDim.inc",
    "MiniFramebufferUserClient.inc",
    "AnnibaleGPU.cpp",
    "AnnibaleGPUMemory.inc",
    "AnnibaleGPUSubmit.inc",
]

# K90's splash region -> star's cont_splash_region (star-B.dtb, loader.c:907)
SPLASH_OLD = "#define FLIP_SPLASH_PHYS        0xfc800000UL    /* DT splash_region, 43 MiB */\n" \
             "#define FLIP_SPLASH_SIZE        0x2b00000UL\n"
SPLASH_NEW = "#define FLIP_SPLASH_PHYS        0xEA600000UL    /* star cont_splash_region (single, no A/B) */\n" \
             "#define FLIP_SPLASH_SIZE        0x02000000UL    /* 32 MiB: only bounds-checks fb_flip=2 */\n"

CONF = "/root/star26/star-native/iokit/conf/files"
CONF_OLD = "iokit/Kernel/StarDisk.cpp\t\t\toptional iokitcpp\n"
CONF_ADD = (
    "iokit/Kernel/MiniIOSurface.cpp\t\t\toptional iokitcpp\n"
    "iokit/Kernel/MiniIOMobileFramebuffer.cpp\t\toptional iokitcpp\n"
    "iokit/Kernel/AnnibaleGPU.cpp\t\t\t\toptional iokitcpp\n"
)


def main():
    missing = [f for f in FILES if not os.path.exists(os.path.join(SRC, f))]
    if missing:
        sys.exit("missing in the K90 tree: %s" % ", ".join(missing))

    print("=== 1. copy the ABI layer (%d files) ===" % len(FILES))
    for f in FILES:
        a, b = os.path.join(SRC, f), os.path.join(DST, f)
        shutil.copyfile(a, b)
        print("  %-34s %7d bytes" % (f, os.path.getsize(b)))

    print("=== 2. star's splash region instead of K90's ===")
    flip = os.path.join(DST, "MiniFramebufferFlip.inc")
    t = open(flip, encoding="utf-8").read()
    if SPLASH_NEW in t:
        print("  MiniFramebufferFlip.inc  already applied")
    else:
        assert SPLASH_OLD in t, "splash constants do not look like the K90 tree"
        open(flip, "w", encoding="utf-8").write(t.replace(SPLASH_OLD, SPLASH_NEW))
        print("  MiniFramebufferFlip.inc  0xfc800000 -> 0xEA600000, 43 MiB -> 32 MiB")

    print("=== 3. register in iokit/conf/files ===")
    c = open(CONF, encoding="utf-8").read()
    if "MiniIOSurface.cpp" in c:
        print("  already registered")
    else:
        assert CONF_OLD in c, "unexpected iokit/conf/files layout"
        open(CONF, "w", encoding="utf-8").write(c.replace(CONF_OLD, CONF_OLD + CONF_ADD))
        print("  + MiniIOSurface / MiniIOMobileFramebuffer / AnnibaleGPU")

    print("=== 4. annibale symbols the copied code still needs ===")
    need = set()
    for f in ("MiniIOMobileFramebuffer.cpp", "AnnibaleGPU.cpp", "MiniIOSurface.cpp"):
        for line in open(os.path.join(DST, f), encoding="utf-8", errors="ignore"):
            line = line.strip()
            if 'extern "C"' in line and "annibale" in line:
                need.add(line)
    for n in sorted(need):
        print("  " + n)
    print("DONE (no device was touched)")


if __name__ == "__main__":
    main()
