#!/usr/bin/env python3
"""stage 8: keep the kalloc section constants in step with the real kernel.

osfmk/kern/kalloc.c carries a Linux/cctools build fixup that has to name the
__kalloc_type / __kalloc_var section offsets as immediates.  Those offsets are
properties of the LINKED kernel: any change that moves __DATA_CONST moves them.

s1 panicked at _kalloc_type_view_copy +0xd4 for exactly this reason (the
constants were the K90 kernel's).  stage 4 measured star-native's values and
wrote them in; stage 7 then added ~127 KB of display code, the sections moved
again, and s7 panicked at the same instruction (esr=0x96000006, read fault,
far outside the kernel window).

So this script does not carry numbers: it reads them out of the built kernel
and writes them into the source.  Run it after every build that changes code
size; `--check` is the gate.

  python3 stage8-kalloc-backfill.py            # measure + write
  python3 stage8-kalloc-backfill.py --check    # measure + compare only
"""
import argparse
import os
import re
import struct
import sys

DST = "/root/star26/star-native"
KALLOC = DST + "/osfmk/kern/kalloc.c"
KERNEL = DST + "/BUILD/obj/RELEASE_ARM64_BCM2837/mach.release.bcm2837.unstripped"

# Both pairs of constants in kalloc.c use this exact shape.
DELTA_RE = re.compile(r"(vm_offset_t kt_delta = \(type == KTV_FIXED\) \? )0x([0-9a-fA-F]+)( : )0x([0-9a-fA-F]+)(;)")
SIZE_RE = re.compile(r"(vm_offset_t kt_size  = \(type == KTV_FIXED\) \? )0x([0-9a-fA-F]+)( : )0x([0-9a-fA-F]+)(;)")


def measured():
    """(fixed_delta, var_delta, fixed_size, var_size) from the linked kernel."""
    d = open(KERNEL, "rb").read()
    magic, cputype, cpusubtype, filetype, ncmds, sizeofcmds, flags = \
        struct.unpack_from("<IiiIIII", d, 0)
    if magic != 0xfeedfacf:
        sys.exit("%s is not a 64-bit Mach-O" % KERNEL)
    base, found, off = None, {}, 32  # mach_header_64: 32 bytes before the load commands
    for _ in range(ncmds):
        cmd, size = struct.unpack_from("<II", d, off)
        if cmd == 0x19:  # LC_SEGMENT_64
            segname = d[off + 8:off + 24].split(b"\0", 1)[0]
            vmaddr, vmsize, fileoff, filesize = struct.unpack_from("<QQQQ", d, off + 24)
            nsects = struct.unpack_from("<I", d, off + 64)[0]
            if segname == b"__TEXT":
                base = vmaddr
            so = off + 72
            for _ in range(nsects):
                sect = d[so:so + 16].split(b"\0", 1)[0]
                addr, sz = struct.unpack_from("<QQ", d, so + 32)
                if sect in (b"__kalloc_type", b"__kalloc_var"):
                    found[sect] = (addr, sz)
                so += 80
        off += size
    if base is None or len(found) != 2:
        sys.exit("cannot locate __TEXT / kalloc sections in %s" % KERNEL)
    t = found[b"__kalloc_type"]
    v = found[b"__kalloc_var"]
    return (t[0] - base, v[0] - base, t[1], v[1])


def read_source():
    text = open(KALLOC, encoding="utf-8").read()
    dm = DELTA_RE.search(text)
    sm = SIZE_RE.search(text)
    if dm is None or sm is None:
        sys.exit("kalloc.c no longer has the expected kt_delta/kt_size shape")
    return text, (int(dm.group(2), 16), int(dm.group(4), 16),
                  int(sm.group(2), 16), int(sm.group(4), 16))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--check", action="store_true")
    args = ap.parse_args()

    want = measured()
    text, have = read_source()
    names = ("__kalloc_type delta", "__kalloc_var delta",
             "__kalloc_type size", "__kalloc_var size")

    print("=== stage 8: kernel says / kalloc.c has ===")
    bad = 0
    for n, w, h in zip(names, want, have):
        ok = w == h
        bad += 0 if ok else 1
        print("  %-4s %-20s kernel=0x%-8x source=0x%-8x" %
              ("OK" if ok else "STALE", n, w, h))

    if args.check:
        if bad:
            raise SystemExit("stage 8: %d constant(s) stale -- run without --check" % bad)
        print("PASS")
        return

    if bad == 0:
        print("nothing to write")
        return

    text = DELTA_RE.sub(lambda m: "%s0x%x%s0x%x%s" %
                        (m.group(1), want[0], m.group(3), want[1], m.group(5)), text)
    text = SIZE_RE.sub(lambda m: "%s0x%x%s0x%x%s" %
                       (m.group(1), want[2], m.group(3), want[3], m.group(5)), text)
    open(KALLOC, "w", encoding="utf-8").write(text)
    print("wrote %s" % KALLOC)
    _, after = read_source()
    if after != want:
        raise SystemExit("write did not take: %r != %r" % (after, want))
    print("verified in source")


if __name__ == "__main__":
    main()
