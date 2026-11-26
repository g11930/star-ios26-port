#!/bin/bash
# s92: check if MACF/mach calls are compiled in the linked kernel — search disassembly for mac_policy_register
K=/root/star26/s91/parts/kernel
# Mach-O arm64: use objdump if available, else strings proximity check
command -v objdump >/dev/null 2>&1 && objdump -d "$K" 2>/dev/null | grep -c 'mac_policy_register'
echo "===SEARCH-BYTES==="
# mac_policy_register symbol string won't be in release binary (no symbol table). Check via .o file imports:
python3 - <<'EOF'
import struct
# parse Mach-O object: find undefined symbol table entries
import sys
def read_macho(path):
    with open(path,'rb') as f: data=f.read()
    magic=struct.unpack('<I',data[:4])[0]
    if magic!=0xcffaedfe and magic!=0xfeedfacf:
        print('not macho or byte-swapped:',hex(magic)); return
    # MH_MAGIC_64=0xfeedfacf little endian
    ncmds=struct.unpack('<I',data[16:20])[0]
    off=32
    symtab=None
    for _ in range(ncmds):
        cmd,cmdsize=struct.unpack('<II',data[off:off+8])
        if cmd==0x2: # LC_SYMTAB
            stroff,nsyms=struct.unpack('<II',data[off+8:off+16])
            strod=struct.unpack('<I',data[off+16:off+20])[0]
            symtab=(strod,nsyms,data[off+12:off+16])
        off+=cmdsize
    if not symtab: print('no symtab'); return
    strod,nsyms,=_ = symtab[0],symtab[1],None
    strtable=data[symtab[0]:symtab[0]+ (symtab[1] if False else 0)]
    # simpler: read n_strx+type fields
    print('nsyms',nsyms)
    for i in range(nsyms):
        e=off=0
    # Actually easiest: strings in strtable region between stroff and stroff+strsize
    # re-read cmd
    off=32
    for _ in range(ncmds):
        cmd,cmdsize=struct.unpack('<II',data[off:off+8])
        if cmd==0x2:
            symoff,nsyms,stroff,strsize=struct.unpack('<IIII',data[off+8:off+24])
            strdata=data[stroff:stroff+strsize]
            names=[s for s in strdata.split(b'\x00') if s]
            interesting=[n.decode(errors='replace') for n in names if b'mac_policy' in n or b'miniamfi' in n or b'minisandbox' in n or b'mac_' in n]
            for n in interesting[:40]: print(n)
        off+=cmdsize
read_macho('/root/star26/star-native/BUILD/obj/RELEASE_ARM64_BCM2837/bsd/RELEASE/kern_minimac.o')
EOF
