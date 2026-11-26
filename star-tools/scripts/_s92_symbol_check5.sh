#!/bin/bash
# s92: simpler — use ctypes/otool-like: check kern_minimac.o undefined syms with xcrun-like tool from xnu deps
O=/root/star26/star-native/BUILD/obj/RELEASE_ARM64_BCM2837/bsd/RELEASE/kern_minimac.o
python3 - <<'EOF'
import struct
data=open('/root/star26/star-native/BUILD/obj/RELEASE_ARM64_BCM2837/bsd/RELEASE/kern_minimac.o','rb').read()
magic=data[:4]
print('magic',magic.hex())
# mach-o 64 LE: magic 0xfeedfacf bytes cf fa ed fe
if magic==b'\xcf\xfa\xed\xfe':
    cputype=struct.unpack('<I',data[4:8])[0]
    ncmds=struct.unpack('<I',data[16:20])[0]
    sizeofcmds=struct.unpack('<I',data[20:24])[0]
    print('cputype',cputype,'ncmds',ncmds)
    off=32
    for _ in range(ncmds):
        cmd,cmdsize=struct.unpack('<II',data[off:off+8])
        if cmd==0x2:  # LC_SYMTAB
            symoff,nsyms,stroff,strsize=struct.unpack('<IIII',data[off+8:off+24])
            strdata=data[stroff:stroff+strsize]
            names=[s.decode(errors='replace') for s in strdata.split(b'\x00') if s]
            undef=[n for n in names if not n.startswith('_'+ '_') ]
            hits=[n for n in names if 'mac_policy' in n or 'miniamfi' in n or 'minisandbox' in n or 'cs_blob' in n or 'CS_' in n.upper()]
            print('total syms',len(names))
            for h in hits: print(' ',h)
        off+=cmdsize
else:
    print('unexpected magic — possibly LLVM bitcode or LTO object')
EOF
