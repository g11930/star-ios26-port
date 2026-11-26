#!/bin/bash
TC=/root/theos/toolchain/linux/iphone/bin
D=/root/star26/hackios-xnu-userland/userland/obj/libannibale-sb26.dylib
"$TC/ldid" -S "$D" && echo RESIGNED
md5sum "$D"
python3 - "$D" <<'PY'
import struct,sys
d=open(sys.argv[1],'rb').read()
cpu,sub=struct.unpack_from('<ii',d,4)
print('cputype=%#x cpusubtype=%#x size=%d' % (cpu&0xffffffff, sub&0xffffffff, len(d)))
PY
