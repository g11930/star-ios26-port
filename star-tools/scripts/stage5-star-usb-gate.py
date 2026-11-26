#!/usr/bin/env python3
"""stage 5: keep the loader's USB/fastboot endpoint alive on star / SM8350
while a live XNU kernel is running.

Evidence (s1 vs s2/s3, 2026-11-15):
  * s1: kernel panicked at 958 bytes, before it touched the GIC or UFS ->
    loader answered `getvar result` the whole time.
  * s2/s3: kernel passed early init (s3 even drew scrolling verbose text on
    the panel) -> loader's USB endpoint went silent for the entire run and
    the logdump stopped at ~4.8 KB, so no kernel log ever reached the host.

`loader_03_ufs_block_watch.inc` already contains the exact remedy, but gates
it on `PLAT == &platform_annibale` only: set watching_only=1 and mask the
firmware IRQ handlers before XNU re-programs the GIC distributor.  Both
phones use the same *polled* USB implementation, so star needs it too.
Rather than hard-code a second platform identity, this patch turns the
condition into a platform capability flag and sets it on both phones.

Single variable, zero kernel changes, zero DPU/framebuffer writes.
`--check` is read-only; default mode is idempotent.
"""
import os
import sys

ROOT = "/root/star26/hackios-xnu-kernel/xnuloader"
HDR = ROOT + "/platform_private.h"
WATCH = ROOT + "/loader_03_ufs_block_watch.inc"

# 1. struct field -----------------------------------------------------------
HDR_OLD = (
    "\tint log_other_cpu;               /* keep notes in the log partition while a kernel starts on another core */\n"
)
HDR_NEW = (
    "\tint log_other_cpu;               /* keep notes in the log partition while a kernel starts on another core */\n"
    "\tint mask_firmware_irq;           /* polled USB: mask firmware IRQ handlers before XNU re-programs the GIC */\n"
)

# 2. annibale initializer ---------------------------------------------------
ANN_OLD = (
    "\t * what a device without a probe wire wants. Flip when the pad is instrumented.\n"
    "\t */\n"
    "\t.uart = 0, .log_other_cpu = 1,\n"
)
ANN_NEW = (
    "\t * what a device without a probe wire wants. Flip when the pad is instrumented.\n"
    "\t */\n"
    "\t.uart = 0, .log_other_cpu = 1, .mask_firmware_irq = 1,\n"
)

# 3. star initializer -------------------------------------------------------
STAR_OLD = (
    "\t.gic_redist_stride = 0x20000,\n"
    "\t.uart = 0, .log_other_cpu = 1,\n"
)
STAR_NEW = (
    "\t.gic_redist_stride = 0x20000,\n"
    "\t.uart = 0, .log_other_cpu = 1, .mask_firmware_irq = 1,\n"
)

# 4. the gate itself --------------------------------------------------------
WATCH_OLD = (
    "\t/* annibale uses polled USB; keep firmware IRQ handlers out of XNU's GIC setup. The mask\n"
    "\t * records the state the release point hands back, and a refused request restores it below. */\n"
    "\tif (PLAT == &platform_annibale) {\n"
    "\t\twatching_only = 1;\n"
    "\t\theld_irq_mask();\n"
    "\t}\n"
)
WATCH_NEW = (
    "\t/* Both phones use polled USB: keep firmware IRQ handlers out of XNU's GIC setup.\n"
    "\t * A live kernel re-programs the distributor, which corrupts firmware IRQ state and\n"
    "\t * takes the loader's USB/fastboot endpoint down.  The mask records the state the\n"
    "\t * release point hands back, and a refused request restores it below.\n"
    "\t * star / SM8350 needs this exactly as much as annibale / SM8750: without it the\n"
    "\t * loader stopped answering after the kernel started (s2/s3, 2026-11-15). */\n"
    "\tif (PLAT->mask_firmware_irq) {\n"
    "\t\twatching_only = 1;\n"
    "\t\theld_irq_mask();\n"
    "\t}\n"
)

EDITS = (
    (HDR, HDR_OLD, HDR_NEW),
    (HDR, ANN_OLD, ANN_NEW),
    (HDR, STAR_OLD, STAR_NEW),
    (WATCH, WATCH_OLD, WATCH_NEW),
)


def read(path):
    return open(path, "r", encoding="utf-8", newline="").read()


def main():
    check = "--check" in sys.argv
    print("=== stage 5: star firmware-IRQ / USB gate (%s) ===" %
          ("READ-ONLY CHECK" if check else "APPLY"))
    text = {p: read(p) for p in (HDR, WATCH)}

    if check:
        ok = True
        # Stage 6 deliberately rewrites the star initializer (log_other_cpu
        # 1->0) while keeping .mask_firmware_irq=1, so that edit's exact text
        # is allowed to differ here.
        star6 = STAR_NEW.replace(".log_other_cpu = 1,", ".log_other_cpu = 0,")
        for idx, (path, old, new) in enumerate(EDITS):
            got = text[path].count(new)
            if idx == 2 and got == 0 and text[path].count(star6) == 1:
                got = 1   # stage-6 variant is fine
            # The struct-field edit appends after `old`, so `old` legitimately
            # survives as a prefix of `new`; only the other three must be gone.
            expect_stale = 1 if new.startswith(old) else 0
            stale = text[path].count(old)
            print("  %-34s applied=%d stale=%d (expect %d)" %
                  (os.path.basename(path), got, stale, expect_stale))
            if got != 1 or stale != expect_stale:
                ok = False
        print("  struct/flag counts: mask_firmware_irq=%d  PLAT->mask_firmware_irq=%d" %
              (text[HDR].count("mask_firmware_irq"),
               text[WATCH].count("PLAT->mask_firmware_irq")))
        print("CHECK %s" % ("PASS" if ok else "FAIL"))
        return 0 if ok else 1

    changed = 0
    star6 = STAR_NEW.replace(".log_other_cpu = 1,", ".log_other_cpu = 0,")
    for idx, (path, old, new) in enumerate(EDITS):
        t = text[path]
        # Edit 0 appends after `old`, so `old` always survives as a prefix of
        # `new`: the presence of a single `new` is the idempotence test here.
        already = ((new in t and old not in t) or
                   (idx == 0 and t.count(new) == 1) or
                   (idx == 2 and star6 in t))
        if already:
            print("  %-34s already applied" % os.path.basename(path))
            continue
        n = t.count(old)
        if n != 1:
            raise SystemExit("EDIT FAILED %s: expected 1 old block, got %d" %
                             (path, n))
        text[path] = t.replace(old, new, 1)
        changed += 1
        print("  %-34s patched" % os.path.basename(path))
    for path, t in text.items():
        open(path, "w", encoding="utf-8", newline="").write(t)

    print("  %d edit(s) written" % changed)
    return 0


if __name__ == "__main__":
    sys.exit(main())
