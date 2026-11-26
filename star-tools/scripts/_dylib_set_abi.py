import struct, sys, hashlib
p='/root/star26/hackios-xnu-userland/userland/obj/libannibale-sb26.dylib'
d=bytearray(open(p,'rb').read())
assert d[:4] == b'\xcf\xfa\xed\xfe', 'not little-endian Mach-O 64'
cpu, sub = struct.unpack_from('<ii', d, 4)
print('before: cputype=%#x cpusubtype=%#x' % (cpu & 0xffffffff, sub & 0xffffffff))
# old working dylib: cputype 0x100000c, cpusubtype 0x80000002 (arm64e + CPU_SUBTYPE_PTRAUTH_ABI)
want = 0x80000002
if (sub & 0xffffffff) != want:
    struct.pack_into('<I', d, 8, want)
    open(p,'wb').write(d)
    print('patched cpusubtype ->', hex(want))
else:
    print('already correct')
# verify
d2=open(p,'rb').read()
cpu2,sub2=struct.unpack_from('<ii',d2,4)
print('after: cputype=%#x cpusubtype=%#x  md5=%s  size=%d' %
      (cpu2&0xffffffff, sub2&0xffffffff, hashlib.md5(d2).hexdigest(), len(d2)))
