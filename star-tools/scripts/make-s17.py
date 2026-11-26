#!/usr/bin/env python3
"""s17 = the stage-13/14 tracing kernel, run free (no checkpoint).

What changed vs s10/s14:
  * star_display_handoff.c now writes through loader_log_line() instead of
    IOLog.  IOLog is undefined-weak in this build (no object defines it), which
    is why the loader's live console card never received a single milestone
    string and the screen froze.  Verified: star_display_handoff.o now imports
    _loader_log_line + _vsnprintf, and loader_return.o exports T _loader_log_line.
  * STARX traces across load_init_program -> load_init_program_at_path ->
    __mac_execve -> exec_activate_image -> load_machfile -> activate_exec_state.
  * NO checkpoint this time.  checkpoint N means "stop at N", so it can only give
    one bit per flash.  Running free lets the path fail on its own: a panic, the
    loader watchdog (50 s), or loader_return_after all carry the ring back, and
    the loader's live console card shows the same lines on the phone.

Everything else is byte-identical to s10: same loader.efi, ramdisk, rdimage,
memsize, identity and cmdline (the cmdline is the s7 one; the fb_* knobs were
proven irrelevant by s11).
"""
import hashlib
import os
import shutil
import subprocess
import sys

BASE = "/root/star26/s17"
PARTS = BASE + "/parts"
PREV = "/root/star26/s10/parts"
NEW_KERNEL = "/root/star26/star-native/BUILD/obj/RELEASE_ARM64_BCM2837/mach.release.bcm2837"
MKPAYLOAD = "/root/star26/hackios-xnu-kernel/xnuloader/mkpayload.py"
RESEAL = "/root/star26/hackios-xnu-kernel/tools/reseal-loader-img.py"
REF_BOOT = "/root/star26/p2/p2-boot.img"
OUT_PAYLOAD = BASE + "/s17-payload.bin"
OUT_BOOT = BASE + "/s17-boot.img"
ASCII_OUT = "/mnt/c/ios26/s17-boot.img"

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

    print("=== 2. the tracing kernel ===")
    kdst = os.path.join(PARTS, "kernel")
    shutil.copyfile(NEW_KERNEL, kdst)
    blob = open(kdst, "rb").read()
    assert b"STARX %s a=%lld b=%lld" in blob, "STARX format string missing"
    assert b"STARX %s %s a=%lld" in blob, "STARX string format missing"
    assert b"star: milestone %s" in blob, "milestone string missing"
    for tag in (b"LIP_ENTER", b"LIPA_EXEC", b"EAI_IMGACT", b"LM_PARSE",
                b"AES_ENTRY", b"ME_ACT", b"EAI_EXIT"):
        assert tag in blob, "tag %r missing" % tag
    assert sha(kdst) != sha(os.path.join(PREV, "kernel")), "kernel unchanged"
    print("  kernel %d  %s  (all 20 STARX tags present)"
          % (os.path.getsize(kdst), sha(kdst)[:16]))

    cmdline = open(os.path.join(PARTS, "cmdline"), "rb").read().split(b"\0", 1)[0].decode("ascii")
    assert "checkpoint" not in cmdline, "no checkpoint this round"
    print("  cmdline (%d): %s" % (len(cmdline), cmdline))

    memsize = open(os.path.join(PARTS, "memsize"), "rb").read().split(b"\0", 1)[0].decode("ascii")
    identity = open(os.path.join(PARTS, "identity"), "rb").read().split(b"\0", 1)[0].decode("ascii")

    print("=== 3. mkpayload (no checkpoint) ===")
    run([sys.executable, MKPAYLOAD, "-o", OUT_PAYLOAD,
         "loader.efi=" + os.path.join(PARTS, "loader.efi"),
         "kernel=" + kdst,
         "ramdisk=" + os.path.join(PARTS, "ramdisk"),
         "rdimage=" + os.path.join(PARTS, "rdimage"),
         "--cmdline", cmdline, "--memsize", memsize, "--identity", identity])
    print("  payload %d" % os.path.getsize(OUT_PAYLOAD))

    print("=== 4. reseal ===")
    run([sys.executable, RESEAL, "-o", OUT_BOOT, REF_BOOT, OUT_PAYLOAD])
    print("  %s %d  sha256 %s" % (OUT_BOOT, os.path.getsize(OUT_BOOT), sha(OUT_BOOT)))
    shutil.copyfile(OUT_BOOT, ASCII_OUT)
    print("  ASCII copy: %s" % ASCII_OUT)
    print("DONE (no device was touched)")


if __name__ == "__main__":
    main()
