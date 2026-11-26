#!/usr/bin/env python3
"""stage 6 (plan A): star must NOT write the logdump partition while a live
XNU kernel owns the UFS controller.

Root cause found in s4 (2026-11-15):
  s1 log : "core 700: the firmware answers 0"
           -> "log: 8192 bytes written to logdump"
           -> "N s: the kernel has logged 958 bytes" every 2 s
  s4 log : "core 700: the firmware answers 0"  <-- END OF LOG, nothing after

That line is loader_03_ufs_block_watch.inc:903; the very next statement is
`if (PLAT->log_other_cpu) flush_log();` (:913).  flush_log() calls UEFI
BlockIo->write_blocks() on the logdump partition.  Because
skip_ufs_arbitration is 1 on this phone, the guard at
loader_01_base_log_dt.inc:534 is bypassed and the write blocks forever once
XNU's native UFS driver has taken the controller.  The watch core never
enters its loop, so usb_poll_command() is never called again: fastboot dies
and the logdump stops at ~4.8 KB.  That is why s2/s3/s4 produced no kernel
log, and why the stage-5 GIC/IRQ theory was wrong.

Fix: platform_star.log_other_cpu = 0.  Combined with stage 5's
watching_only=1, there is then no flush_log() at all during a run.  The
kernel log is read from RAM instead: `oem log` -> compose_live_log().

Single variable, loader only.  `--check` is read-only; default is idempotent.
"""
import sys

HDR = "/root/star26/hackios-xnu-kernel/xnuloader/platform_private.h"

OLD = (
    "\t.gic_redist_stride = 0x20000,\n"
    "\t.uart = 0, .log_other_cpu = 1, .mask_firmware_irq = 1,\n"
)
NEW = (
    "\t/* star's kernel takes the UFS controller over (ufs_native=1 +\n"
    "\t * annibale_ufs_init).  A loader BlockIo write to logdump from the\n"
    "\t * watch core blocks forever there, which also kills USB/fastboot.\n"
    "\t * Leave log_other_cpu=0: read the live kernel log from RAM with\n"
    "\t * `oem log` (compose_live_log) instead.  See stage6 notes, s4. */\n"
    "\t.gic_redist_stride = 0x20000,\n"
    "\t.uart = 0, .log_other_cpu = 0, .mask_firmware_irq = 1,\n"
)


def main():
    check = "--check" in sys.argv
    t = open(HDR, "r", encoding="utf-8", newline="").read()
    print("=== stage 6: star log_other_cpu=0 (%s) ===" %
          ("READ-ONLY CHECK" if check else "APPLY"))
    if check:
        ok = (t.count(NEW) == 1 and t.count(OLD) == 0 and
              t.count(".uart = 0, .log_other_cpu = 1, .mask_firmware_irq = 1,") == 1)
        print("  star block applied=%d stale=%d ; annibale still log_other_cpu=1: %s" %
              (t.count(NEW), t.count(OLD),
               t.count(".uart = 0, .log_other_cpu = 1, .mask_firmware_irq = 1,") == 1))
        print("CHECK %s" % ("PASS" if ok else "FAIL"))
        return 0 if ok else 1
    if NEW in t and OLD not in t:
        print("  already applied")
        return 0
    n = t.count(OLD)
    if n != 1:
        raise SystemExit("EDIT FAILED: expected 1 star initializer, got %d" % n)
    open(HDR, "w", encoding="utf-8", newline="").write(t.replace(OLD, NEW, 1))
    print("  patched %s" % HDR)
    return 0


if __name__ == "__main__":
    sys.exit(main())
