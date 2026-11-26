#!/bin/bash
# Compare the arm64e kernel against the saved arm64 one: segment layout, ptrauth
# instructions, and which sections are new. A checkpoint-1 miss means the kernel
# dies before the first C line of arm_vm_init, so look at load-time structures.
python3 - <<'PY'
import struct, os

S19 = '/root/star26/star-native/BUILD/obj/RELEASE_ARM64_BCM2837/mach.release.bcm2837'
BAK = '/root/star26/mach.arm64.bak'

def segs(p):
    d = open(p, 'rb').read()
    magic, cputype, cpusub, ft, ncmds, szcmds, flags, res = struct.unpack_from('<IiiIIIII', d, 0)
    out = []
    off = 32
    for _ in range(ncmds):
        cmd, size = struct.unpack_from('<II', d, off)
        if cmd == 0x19:
            name = d[off+8:off+24].split(b'\0', 1)[0].decode()
            vmaddr, vmsize, fileoff, filesize = struct.unpack_from('<QQQQ', d, off+24)
            maxprot, initprot, nsects, sflags = struct.unpack_from('<iiII', d, off+56)
            out.append((name, vmaddr, vmsize, fileoff, filesize, initprot, sflags, off))
        off += size
    return d, out, (cputype & 0xffffffff, cpusub & 0xffffffff)

for tag, p in (('arm64 ', BAK), ('arm64e', S19)):
    if not os.path.exists(p):
        print(tag, 'MISSING', p); continue
    d, s, cpu = segs(p)
    print('=== %s  size %d  cputype %#x cpusubtype %#x' % (tag, len(d), cpu[0], cpu[1]))
    for (n, va, vs, fo, fs, ip, fl, o) in s:
        print('   %-14s vm %#012x size %-9d fileoff %#-8x filesize %-9d initprot %d flags %#x' %
              (n, va, vs, fo, fs, ip, fl))
PY
