#!/bin/bash
# mks54.sh -- s54 = s53 with the interposer fixed.  Same inject.conf, same cmdline, same kernel.
#
# What s53's samples actually proved, read together with the log's line counts: exactly 120
# "SpringBoard IOServiceMatching" lines -- the trace cap -- and the CPU still pegged for the
# next 200 s.  A caller that stops logging at the cap and keeps burning a core is a call that
# never returns, and the only call that cannot return here is the one to the "original" that
# dlsym(RTLD_NEXT) handed over: it was this library's own replacement, and `return real(name)`
# is a tail call, which the compiler turns into a jump.  s52 and s53 therefore measured their
# own probe, not SpringBoard.
#
# So this round changes the resolution and nothing else: the original now comes from a handle
# to IOKit.framework itself, the pointers are compared against the replacements at
# construction, and if they still come back as this library the interposing is switched off
# with a line that says so.  Depth guards make a self-call one level deep instead of a loop,
# and the four call counters are logged uncapped in every beat, so "one call stuck" and
# "a million calls" can never again look the same.
set -e
U=/root/star26/hackios-xnu-userland/userland
LD64=/root/theos/toolchain/linux/iphone/bin/ld
SDK=/root/theos/sdks/iPhoneOS16.5.sdk
LDID=/root/theos/toolchain/linux/iphone/bin/ldid

mkdir -p /root/star26/s54/work
rm -rf /root/star26/s54/work/root
cp -a /root/star26/s53/work/root /root/star26/s54/work/root

echo "=== 1. build libsbtrace.dylib (IOKit handle + depth guards + counters)"
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
cp -f obj/libsbtrace.dylib /root/star26/s54/work/root/lib/libsbtrace.dylib

echo "=== 2. inject.conf (unchanged)"
head -2 /root/star26/s54/work/root/etc/inject.conf

echo "=== 3. root.apfs"
cd /root/star26/s54/work
python3 /root/star26/hackios-xnu-userland/tools/apfs/mkapfs.py -z --plain fw \
	-o /root/star26/s54/root.apfs annibale=root 2>&1 | tail -1

echo "=== 4. boot image"
cd /root/star26/star-native
python3 /mnt/d/桌面/star26-deps/scripts/make-boot.py s54 s53 "" 2>&1 | tail -3
bash /mnt/d/桌面/star26-deps/scripts/repack-ramdisk.sh s54 2>&1 | tail -4
echo "== cmdline =="
tr -d '\0' < /root/star26/s54/parts/cmdline
echo
ls -l /root/star26/s54/s54-boot.img
