#!/bin/bash
OBJ=/root/star26/hackios-xnu-userland/userland/obj/libannibale-sb26.dylib
echo "=== restore correct 0x80000002 dylib (keep source patch, revert bad clang18 build) ==="
cp -f "$OBJ.s213-pre" "$OBJ"
md5sum "$OBJ"
python3 - "$OBJ" <<'PY'
import struct,sys
d=open(sys.argv[1],'rb').read()
cpu,sub=struct.unpack_from('<ii',d,4)
print('cputype=%#x cpusubtype=%#x (expect 0x80000002)' % (cpu&0xffffffff,sub&0xffffffff))
PY
echo "=== clean my SDK backup leftovers ==="
rm -f /root/star26/hackios-xnu-userland/userland/xnu-deps/26/sdk/iPhoneOS.sdk/usr/include/Availability.h.s213bak
rm -f /root/star26/hackios-xnu-userland/userland/xnu-deps/26/sdk/iPhoneOS.sdk/usr/include/os/availability.h.s213bak
echo "cleaned"
