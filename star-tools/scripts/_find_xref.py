#!/usr/bin/env python3
"""Find the 'instruction type %u' string in libannibaleair.dylib and locate the
code that references it (adrp+add pairs), then dump that function region."""
import sys, struct, subprocess, os, re

PATH = sys.argv[1] if len(sys.argv) > 1 else "/root/star26/s42/work/root/lib/libannibaleair.dylib"
data = open(PATH, "rb").read()

NEEDLE = b"softpipe half lowering does not support instruction type"
off = data.find(NEEDLE)
print("string file offset: %#x" % off if off >= 0 else "NOT FOUND")

# --- parse mach-o segments to map vmaddr <-> file offset
magic = struct.unpack("<I", data[:4])[0]
assert magic == 0xfeedfacf, hex(magic)
ncmds = struct.unpack("<I", data[16:20])[0]
p = 32
segs = []
for _ in range(ncmds):
    cmd, cmdsize = struct.unpack("<II", data[p:p+8])
    if cmd == 0x19:  # LC_SEGMENT_64
        name = data[p+8:p+24].rstrip(b"\x00").decode()
        vmaddr, vmsize = struct.unpack("<QQ", data[p+24:p+40])
        fileoff, filesize = struct.unpack("<QQ", data[p+40:p+56])
        segs.append((name, vmaddr, vmsize, fileoff, filesize))
    p += cmdsize

def off2va(o):
    for name, va, vs, fo, fs in segs:
        if fo <= o < fo + fs:
            return va + (o - fo)
    return None

def va2off(v):
    for name, va, vs, fo, fs in segs:
        if va <= v < va + vs:
            return fo + (v - va)
    return None

print("segments:")
for s in segs:
    print("  %-16s va=%#x vmsize=%#x fileoff=%#x filesize=%#x" % s)

sva = off2va(off)
print("string vmaddr = %#x" % sva)

# --- find adrp/add pairs that form this address
text = None
for name, va, vs, fo, fs in segs:
    if name == "__TEXT":
        text = (va, fo, fs)
        break

print("TEXT va=%#x  => page=%#x  low12=%#x" % (sva & ~0xfff, sva & 0xfff, sva & 0xfff))
print("grep pattern: adrp .*0x%x   then add .*#0x%x" % (sva & ~0xfff, sva & 0xfff))
