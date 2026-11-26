#!/bin/bash
# mk-starcat.sh -- build the static starcat into the s39 root tree.
set -e
U=/root/star26/hackios-xnu-userland/userland
HOSTBIN=/root/star26/hackios-xnu-kernel/xnu-deps/host/bin
CC="$HOSTBIN/xnu-clang -arch arm64 -Os -static -nostdlib -ffreestanding -fno-stack-protector -fno-builtin -Wall -Wextra"
LD="-Wl,-e,_start -Wl,-pagezero_size,0x100000000"
OUT=/root/star26/s39/work
mkdir -p $OUT
cd $U
$CC -Ilibmini -c libmini/mini.c -o $OUT/mini.o
$CC -c libmini/start.S -o $OUT/start.o
$CC -Ilibmini $LD -o $OUT/starcat /mnt/d/桌面/star26-deps/scripts/starcat.c $OUT/mini.o $OUT/start.o
file $OUT/starcat 2>/dev/null || true
ls -la $OUT/starcat
python3 - <<'PY'
import struct
d = open('/root/star26/s39/work/starcat','rb').read(32)
magic, cputype, cpusub, ft, ncmds, sz, flags, _ = struct.unpack('<IiiIIIII', d)
print('magic %#x cputype %#x cpusubtype %#x filetype %d ncmds %d' % (magic, cputype & 0xffffffff, cpusub & 0xffffffff, ft, ncmds))
PY
