#!/usr/bin/env python3
"""s18 = the STARX tracing kernel with sequence-numbered checkpoint gates.

Usage:  make-s18.py <checkpoint>  e.g. 213 -> stop at the 13th STARX point

One build, many questions.  The stage-15 kernel calls

    star_gate()  ->  loader_checkpoint(200 + ++seq)

from inside both trace helpers, so passing 200+K makes the kernel stop at the
K-th trace call of the whole boot and hand the log ring -- every STARX line
written up to there -- to the loader.  No recompile between gates.

Trace order (single-threaded bsd_init):

   1 LIP_ENTER       load_init_program entry
   2 LIP_SCRATCH     mach_vm_allocate_kernel returned
   3 LIPA_ENTER      load_init_program_at_path entry (path in b=)
   4 LIPA_COPYOUT    copyout of the program name done (error in a=)
   5 LIPA_EXEC       argv assembled, execve about to be called
   6 ME_ENTER        __mac_execve entry
   7 ME_ACT          exec_activate_image returned (error in a=)
   8 EAI_ALLOC       execargs_alloc done
   9 EAI_NAMEI       namei returned (error in a=)
  10 EAI_PERM        exec_check_permissions returned (error in a=)
  11 EAI_RDWR        header read done (error a=, resid b=)
  12 LM_ENTER        load_machfile entry
  13 LM_PARSE        parse_machfile returned (lret in a=)
  14 EAI_IMGACT      imgact loop finished (index a=, error b=)
  15 EAI_EXIT        exec_activate_image exit
  16 ME_SWITCH       proc_exec_switch_task done
  17 AES_ENTRY       thread_setentrypoint done (entry_point in a=)
  18 LIP_RET         execve returned (error in a=)

Everything else is byte-identical to s10: same loader.efi, ramdisk, rdimage,
memsize, identity and cmdline (the fb_* knobs were proven irrelevant by s11).
"""
import hashlib
import os
import shutil
import subprocess
import sys

CKPT = sys.argv[1] if len(sys.argv) > 1 else "213"
GATE = str(int(CKPT) - 200) if int(CKPT) >= 200 else CKPT

BASE = "/root/star26/s18"
PARTS = BASE + "/parts"
PREV = "/root/star26/s10/parts"
NEW_KERNEL = "/root/star26/star-native/BUILD/obj/RELEASE_ARM64_BCM2837/mach.release.bcm2837"
MKPAYLOAD = "/root/star26/hackios-xnu-kernel/xnuloader/mkpayload.py"
RESEAL = "/root/star26/hackios-xnu-kernel/tools/reseal-loader-img.py"
REF_BOOT = "/root/star26/p2/p2-boot.img"
OUT_PAYLOAD = BASE + "/s18-payload.bin"
OUT_BOOT = BASE + "/s18-boot.img"
ASCII_OUT = "/mnt/c/ios26/s18-boot.img"

SAME = ("loader.efi", "ramdisk", "rdimage", "memsize", "identity", "cmdline")


def sha(path):
    return hashlib.sha256(open(path, "rb").read()).hexdigest()


def run(argv):
    r = subprocess.run(argv, capture_output=True, text=True)
    if r.stdout.strip():
        print("    " + r.stdout.strip().replace("\n", "\n    "))
    if r.returncode != 0:
        print("    STDERR: " + r.stderr.strip())
        raise SystemExit("FAILED: exit %d" % r.returncode)


def main():
    os.makedirs(PARTS, exist_ok=True)

    print("=== 1. s10 parts, byte for byte ===")
    for name in SAME:
        a, b = os.path.join(PREV, name), os.path.join(PARTS, name)
        shutil.copyfile(a, b)
        assert sha(a) == sha(b)
        print("  %-10s %10d  %s" % (name, os.path.getsize(b), sha(b)[:16]))

    print("=== 2. the gated tracing kernel ===")
    kdst = os.path.join(PARTS, "kernel")
    shutil.copyfile(NEW_KERNEL, kdst)
    blob = open(kdst, "rb").read()
    assert b"STARX %s a=%lld b=%lld" in blob, "STARX format string missing"
    assert b"STARX %s %s a=%lld" in blob, "STARX string format missing"
    for tag in (b"LIP_ENTER", b"LIPA_EXEC", b"EAI_IMGACT", b"LM_PARSE",
                b"AES_ENTRY", b"ME_ACT", b"EAI_EXIT"):
        assert tag in blob, "tag %r missing" % tag
    assert sha(kdst) != sha(os.path.join(PREV, "kernel")), "kernel unchanged"
    print("  kernel %d  %s" % (os.path.getsize(kdst), sha(kdst)[:16]))

    cmdline = open(os.path.join(PARTS, "cmdline"), "rb").read().split(b"\0", 1)[0].decode("ascii")
    assert "checkpoint" not in cmdline, "checkpoint belongs in the payload, not the cmdline"
    print("  cmdline (%d): %s" % (len(cmdline), cmdline))

    memsize = open(os.path.join(PARTS, "memsize"), "rb").read().split(b"\0", 1)[0].decode("ascii")
    identity = open(os.path.join(PARTS, "identity"), "rb").read().split(b"\0", 1)[0].decode("ascii")

    print("=== 3. mkpayload --checkpoint %s  (gate %s) ===" % (CKPT, GATE))
    run([sys.executable, MKPAYLOAD, "-o", OUT_PAYLOAD,
         "loader.efi=" + os.path.join(PARTS, "loader.efi"),
         "kernel=" + kdst,
         "ramdisk=" + os.path.join(PARTS, "ramdisk"),
         "rdimage=" + os.path.join(PARTS, "rdimage"),
         "--cmdline", cmdline, "--memsize", memsize, "--identity", identity,
         "--checkpoint", CKPT])
    print("  payload %d" % os.path.getsize(OUT_PAYLOAD))

    print("=== 4. reseal ===")
    run([sys.executable, RESEAL, "-o", OUT_BOOT, REF_BOOT, OUT_PAYLOAD])
    print("  %s %d  sha256 %s" % (OUT_BOOT, os.path.getsize(OUT_BOOT), sha(OUT_BOOT)))
    shutil.copyfile(OUT_BOOT, ASCII_OUT)
    print("  ASCII copy: %s" % ASCII_OUT)
    print("DONE (no device was touched)")


if __name__ == "__main__":
    main()
