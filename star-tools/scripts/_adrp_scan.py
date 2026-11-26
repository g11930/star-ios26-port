#!/usr/bin/env python3
"""Decode adrp instructions in libannibaleair.dylib that target a given page,
then print the surrounding instruction window for each hit."""
import sys, struct, subprocess

PATH = "/root/star26/s42/work/root/lib/libannibaleair.dylib"
TARGET_PAGE = 0xbb1000
TARGET_LOW = 0xa43

data = open(PATH, "rb").read()
magic = struct.unpack("<I", data[:4])[0]
assert magic == 0xfeedfacf
ncmds = struct.unpack("<I", data[16:20])[0]
p = 32
text_va = text_off = text_size = None
for _ in range(ncmds):
    cmd, cmdsize = struct.unpack("<II", data[p:p+8])
    if cmd == 0x19:
        name = data[p+8:p+24].rstrip(b"\x00").decode()
        vmaddr, vmsize, fileoff, filesize = struct.unpack("<QQQQ", data[p+24:p+56])
        if name == "__TEXT":
            text_va, text_off, text_size = vmaddr, fileoff, filesize
    p += cmdsize

# __text section inside __TEXT
p = 32
sect_va = sect_off = sect_size = None
for _ in range(ncmds):
    cmd, cmdsize = struct.unpack("<II", data[p:p+8])
    if cmd == 0x19:
        nsects = struct.unpack("<I", data[p+64:p+68])[0]
        q = p + 72
        for _ in range(nsects):
            sname = data[q:q+16].rstrip(b"\x00").decode()
            addr, size, offset = struct.unpack("<QQI", data[q+32:q+52])
            if sname == "__text":
                sect_va, sect_off, sect_size = addr, offset, size
            q += 80
    p += cmdsize

print("__text va=%#x off=%#x size=%#x" % (sect_va, sect_off, sect_size))

hits = []
for i in range(0, sect_size, 4):
    w = struct.unpack("<I", data[sect_off+i:sect_off+i+4])[0]
    if (w & 0x9F000000) != 0x90000000:   # adrp
        continue
    rd = w & 0x1f
    immlo = (w >> 29) & 3
    immhi = (w >> 5) & 0x7ffff
    imm = (immhi << 2) | immlo
    if imm & (1 << 20):
        imm -= 1 << 21
    pc = sect_va + i
    tgt = (pc & ~0xfff) + (imm << 12)
    if tgt == TARGET_PAGE:
        hits.append((pc, rd))

print("adrp hits to page %#x: %d" % (TARGET_PAGE, len(hits)))
for pc, rd in hits:
    # verify a following add xD, x[rd], #TARGET_LOW within 8 instructions
    ok = False
    for k in range(1, 9):
        o = sect_off + (pc - sect_va) + 4*k
        if o + 4 > len(data):
            break
        w = struct.unpack("<I", data[o:o+4])[0]
        if (w & 0xFF800000) == 0x91000000 and ((w >> 5) & 0x1f) == rd and ((w >> 10) & 0xfff) == TARGET_LOW:
            ok = True
            break
    if ok:
        print("  HIT pc=%#x adrp x%d -> full addr %#x" % (pc, rd, TARGET_PAGE | TARGET_LOW))
