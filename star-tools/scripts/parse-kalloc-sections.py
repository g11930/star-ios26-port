#!/usr/bin/env python3
"""Read __kalloc_type / __kalloc_var section addresses from a Mach-O kernel.

The WSL/Linux cctools build hardcodes kt_delta=0x1d0a08 (fixed) and
0x1c8c18 (var) in osfmk/kern/kalloc.c as offsets from &_mh_execute_header.
Those numbers were measured against the kbuild (K90) kernel.  star-native
removed most platform drivers, so its section layout is different.  This
script prints the real offsets for any kernel so the fixup can be corrected.
"""
import re
import struct
import sys

KALLOC_SECTS = (b"__kalloc_type", b"__kalloc_var")
KALLOC_C = "/root/star26/star-native/osfmk/kern/kalloc.c"


def read_fixup_constants(path):
    """The WSL/cctools fixup hardcodes two deltas and two sizes in kalloc.c."""
    try:
        text = open(path, errors="replace").read()
    except OSError:
        return None
    delta = re.search(r"kt_delta\s*=\s*\(type == KTV_FIXED\)\s*\?\s*(0x[0-9a-f]+)\s*:\s*(0x[0-9a-f]+)", text)
    size = re.search(r"kt_size\s*=\s*\(type == KTV_FIXED\)\s*\?\s*(0x[0-9a-f]+)\s*:\s*(0x[0-9a-f]+)", text)
    if not delta or not size:
        return None
    return {
        b"__kalloc_type": (int(delta.group(1), 16), int(size.group(1), 16)),
        b"__kalloc_var": (int(delta.group(2), 16), int(size.group(2), 16)),
    }


def parse(path):
    d = open(path, "rb").read()
    magic, cputype, cpusubtype, filetype, ncmds, sizeofcmds, flags, res = \
        struct.unpack_from("<IiiIIIII", d, 0)
    assert magic == 0xfeedfacf, "not a Mach-O 64 (magic 0x%08x)" % magic
    off = 32
    base = None
    sects = []
    for _ in range(ncmds):
        cmd, cmdsize = struct.unpack_from("<II", d, off)
        if cmd == 0x19:  # LC_SEGMENT_64
            segname = d[off + 8:off + 24].rstrip(b"\0")
            vmaddr, vmsize, fileoff, filesize = struct.unpack_from("<QQQQ", d, off + 24)
            maxprot, initprot, nsects, segflags = struct.unpack_from("<iiII", d, off + 56)
            if segname == b"__TEXT" and base is None:
                base = vmaddr  # &_mh_execute_header
            so = off + 72
            for _s in range(nsects):
                sectname = d[so:so + 16].rstrip(b"\0")
                sectseg = d[so + 16:so + 32].rstrip(b"\0")
                addr, size = struct.unpack_from("<QQ", d, so + 32)
                so += 80
                if sectname in KALLOC_SECTS:
                    sects.append((sectname.decode(), sectseg.decode(), addr, size))
        off += cmdsize
    return base, sects


def main():
    fix = read_fixup_constants(KALLOC_C)
    bad = 0
    for path in sys.argv[1:]:
        base, sects = parse(path)
        print("\n%s" % path)
        print("  __TEXT vmaddr (&_mh_execute_header) = 0x%x" % (base or 0))
        for name, seg, addr, size in sects:
            print("  %-16s in %-14s addr=0x%016x size=0x%-8x  delta=0x%x" %
                  (name, seg, addr, size, addr - base))
        # Only the current star-native kernel is asserted against kalloc.c;
        # other kernels are printed purely as reference/comparison.
        is_current = "star-native" in path
        for name, seg, addr, size in sects:
            real = (addr - base, size)
            key = name.encode()
            if fix and key in fix:
                want = fix[key]
                ok = real == want
                if is_current and not ok:
                    bad += 1
                state = "OK" if ok else ("MISMATCH" if is_current else "reference")
                print("  %-9s %-16s kalloc.c delta/size = (0x%x, 0x%x), kernel = (0x%x, 0x%x)" %
                      (state, name, want[0], want[1], real[0], real[1]))
            else:
                print("  %-16s kernel delta=0x%x size=0x%x" % (name, real[0], real[1]))
    if fix is None:
        print("\nWARNING: could not read kalloc.c fixup constants from %s" % KALLOC_C)
    elif bad:
        raise SystemExit("\nFAIL: %d kalloc section constant(s) are stale -- rerun "
                         "stage4-kalloc-deltas.py with the measured values" % bad)
    else:
        print("\nPASS: kalloc.c constants match the kernel section layout")


if __name__ == "__main__":
    main()
