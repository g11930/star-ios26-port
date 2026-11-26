#!/bin/bash
# mks53.sh -- s53 = s52 + the sampler inside libsbtrace.dylib.  Nothing else changes.
#
# s52 found the two processes in opposite states: SpringBoard's main thread RUNNING with its CPU
# time climbing 1000 ms every 15 s from the first second (a spin), backboardd's WAITING at
# 1916 ms for 180 s and never making one IOKit lookup.  This round asks the only question that
# makes those two actionable: at which address does SpringBoard spin?
#
# src/sbtrace.c now arms SIGPROF in its constructor; the heartbeat sends it to the main thread
# when that thread is running, and resolves PC/LR/frame-chain with dladdr, so the log line names
# the image and the nearest exported symbol instead of an address nobody can place.
#
# The image is otherwise s52 byte for byte: same inject.conf, same cmdline, same kernel.
set -e
U=/root/star26/hackios-xnu-userland/userland
LD64=/root/theos/toolchain/linux/iphone/bin/ld
SDK=/root/theos/sdks/iPhoneOS16.5.sdk
LDID=/root/theos/toolchain/linux/iphone/bin/ldid

mkdir -p /root/star26/s53/work
rm -rf /root/star26/s53/work/root
cp -a /root/star26/s52/work/root /root/star26/s53/work/root

echo "=== 1. build libsbtrace.dylib with the sampler"
cp -f /mnt/d/桌面/star26-deps/src/sbtrace.c "$U/src/inject/sbtrace.c"
cd "$U"
/usr/bin/clang -target arm64e-apple-ios16.5 --ld-path="$LD64" -isysroot "$SDK" \
	-O1 -arch arm64e -Wall -Wextra \
	-Isrc/boot -Isrc/inject -Isrc/apps \
	-framework IOKit -framework CoreFoundation \
	-dynamiclib -install_name /annibale/lib/libsbtrace.dylib \
	-o obj/libsbtrace.dylib src/inject/sbtrace.c
python3 - <<'PY'
import struct
p = "/root/star26/hackios-xnu-userland/userland/obj/libsbtrace.dylib"
d = bytearray(open(p, "rb").read())
cputype, cpusub = struct.unpack_from("<II", d, 4)
if cpusub == 0x2:
    struct.pack_into("<I", d, 8, 0x80000002)
    open(p, "wb").write(d)
    print("cpusubtype 0x2 -> 0x80000002")
PY
"$LDID" -S obj/libsbtrace.dylib
file obj/libsbtrace.dylib
ls -l obj/libsbtrace.dylib
cp -f obj/libsbtrace.dylib /root/star26/s53/work/root/lib/libsbtrace.dylib

echo "=== 2. inject.conf (unchanged from s52)"
head -1 /root/star26/s53/work/root/etc/inject.conf

echo "=== 3. root.apfs"
cd /root/star26/s53/work
python3 /root/star26/hackios-xnu-userland/tools/apfs/mkapfs.py -z --plain fw \
	-o /root/star26/s53/root.apfs annibale=root 2>&1 | tail -1

echo "=== 4. boot image"
cd /root/star26/star-native
python3 /mnt/d/桌面/star26-deps/scripts/make-boot.py s53 s52 "" 2>&1 | tail -3
bash /mnt/d/桌面/star26-deps/scripts/repack-ramdisk.sh s53 2>&1 | tail -4
echo "== cmdline =="
tr -d '\0' < /root/star26/s53/parts/cmdline
echo
ls -l /root/star26/s53/s53-boot.img
