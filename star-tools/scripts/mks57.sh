#!/bin/bash
# mks57.sh -- s57 = s56 + inject a minimal high-frequency tracer into logd.
#
# s56 found the real blocker: logd dies by SIGTRAP ~1.2 s after launch, 20 times in a row, and
# the corpse machinery saturates ("Corpse failure, too many 6") so no crash report is ever
# written.  The 15 s sbtrace heartbeat cannot catch a 1.2 s life, so a separate library samples
# logd's main thread PC/LR every 100 ms and reports each new PC; the last line before the SIGTRAP
# names where it died.  It does no interposing and no dlopen, to avoid changing logd's behaviour.
set -e
U=/root/star26/hackios-xnu-userland/userland
LD64=/root/theos/toolchain/linux/iphone/bin/ld
SDK=/root/theos/sdks/iPhoneOS16.5.sdk
LDID=/root/theos/toolchain/linux/iphone/bin/ldid

mkdir -p /root/star26/s57/work
rm -rf /root/star26/s57/work/root
cp -a /root/star26/s56/work/root /root/star26/s57/work/root

echo "=== 1. build liblogdtrace.dylib (100ms PC/LR sampler, no interposing)"
cp -f /mnt/d/桌面/star26-deps/src/logdtrace.c "$U/src/inject/logdtrace.c"
cd "$U"
/usr/bin/clang -target arm64e-apple-ios16.5 --ld-path="$LD64" -isysroot "$SDK" \
	-O1 -arch arm64e -Wall -Wextra \
	-Isrc/boot -Isrc/inject -Isrc/apps \
	-dynamiclib -install_name /annibale/lib/liblogdtrace.dylib \
	-o obj/liblogdtrace.dylib src/inject/logdtrace.c
python3 - <<'PY'
import struct
p = "/root/star26/hackios-xnu-userland/userland/obj/liblogdtrace.dylib"
d = bytearray(open(p, "rb").read())
cputype, cpusub = struct.unpack_from("<II", d, 4)
if cpusub == 0x2:
    struct.pack_into("<I", d, 8, 0x80000002)
    open(p, "wb").write(d)
    print("cpusubtype 0x2 -> 0x80000002")
PY
"$LDID" -S obj/liblogdtrace.dylib
file obj/liblogdtrace.dylib
cp -f obj/liblogdtrace.dylib /root/star26/s57/work/root/lib/liblogdtrace.dylib

echo "=== 2. inject.conf: add logd -> liblogdtrace.dylib"
# s56's inject.conf had sbtrace first (SpringBoard backboardd ...), sb26 second, etc.
# Prepend a line so logd gets the minimal tracer and nothing else changes for the others.
{
  echo "/annibale/lib/liblogdtrace.dylib logd"
  cat /root/star26/s57/work/root/etc/inject.conf
} > /tmp/inject56.conf
mv /tmp/inject56.conf /root/star26/s57/work/root/etc/inject.conf
echo "--- new inject.conf ---"
cat /root/star26/s57/work/root/etc/inject.conf

echo "=== 3. root.apfs"
cd /root/star26/s57/work
python3 /root/star26/hackios-xnu-userland/tools/apfs/mkapfs.py -z --plain fw \
	-o /root/star26/s57/root.apfs annibale=root 2>&1 | tail -1

echo "=== 4. boot image"
cd /root/star26/star-native
python3 /mnt/d/桌面/star26-deps/scripts/make-boot.py s57 s56 "" 2>&1 | tail -3
bash /mnt/d/桌面/star26-deps/scripts/repack-ramdisk.sh s57 2>&1 | tail -4
echo "== cmdline =="
tr -d '\0' < /root/star26/s57/parts/cmdline
echo
ls -l /root/star26/s57/s57-boot.img
