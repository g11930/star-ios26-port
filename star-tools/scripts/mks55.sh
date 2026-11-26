#!/bin/bash
# mks55.sh -- s55 = s54 + sample the WAITING main thread (thread_get_state, read-only).
#
# s54's clean probe showed both processes WAITING, stopped early (SpringBoard 4.4 s, backboardd
# 2 s), zero IOKit past the first lookup.  The running sampler never fires on a waiting thread
# (SIGPROF would EINTR the mach_msg and change what is measured), so nothing said where.  This
# round reads the waiting main thread's PC/LR/FP-chain with thread_get_state instead -- no signal,
# the wait is untouched -- and reports the caller that entered the wait.
set -e
U=/root/star26/hackios-xnu-userland/userland
LD64=/root/theos/toolchain/linux/iphone/bin/ld
SDK=/root/theos/sdks/iPhoneOS16.5.sdk
LDID=/root/theos/toolchain/linux/iphone/bin/ldid

mkdir -p /root/star26/s55/work
rm -rf /root/star26/s55/work/root
cp -a /root/star26/s54/work/root /root/star26/s55/work/root

echo "=== 1. build libsbtrace.dylib (+waiting sampler)"
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
cp -f obj/libsbtrace.dylib /root/star26/s55/work/root/lib/libsbtrace.dylib

echo "=== 2. inject.conf (unchanged)"
head -2 /root/star26/s55/work/root/etc/inject.conf

echo "=== 3. root.apfs"
cd /root/star26/s55/work
python3 /root/star26/hackios-xnu-userland/tools/apfs/mkapfs.py -z --plain fw \
	-o /root/star26/s55/root.apfs annibale=root 2>&1 | tail -1

echo "=== 4. boot image"
cd /root/star26/star-native
python3 /mnt/d/桌面/star26-deps/scripts/make-boot.py s55 s54 "" 2>&1 | tail -3
bash /mnt/d/桌面/star26-deps/scripts/repack-ramdisk.sh s55 2>&1 | tail -4
echo "== cmdline =="
tr -d '\0' < /root/star26/s55/parts/cmdline
echo
ls -l /root/star26/s55/s55-boot.img
