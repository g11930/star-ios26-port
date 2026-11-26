#!/bin/bash
echo "=== bash history: sb26 dylib compile ==="
grep -hE 'inject_sb26|libannibale-sb26|xnu-clang.*arm64e|clang.*arm64e' /root/.bash_history /home/*/.bash_history 2>/dev/null | tail -40
echo "=== any build logs with compile command ==="
grep -rlnE 'inject_sb26.c.*inject_sb26_layers' /root/star26 /mnt/c/ios26 2>/dev/null | grep -vE '\.c$|\.sh$' | head -20
echo "=== old dylib LC_BUILD_VERSION / compile hints ==="
python3 - <<'PY'
import struct
p='/root/star26/hackios-xnu-userland/userland/obj/libannibale-sb26.dylib.s213-pre'
d=open(p,'rb').read()
# mach_header_64: magic cputype cpusubtype filetype ncmds sizeofcmds flags reserved
magic,cpu,sub,ftype,ncmds,sizeofcmds,flags,res=struct.unpack_from('<IIIIIIII',d,0)
print('cputype=%#x cpusubtype=%#x filetype=%d ncmds=%d flags=%#x' % (cpu,sub,ftype,ncmds,flags))
PY
