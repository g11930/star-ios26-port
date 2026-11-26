#!/bin/bash
set -e
U=/root/star26/hackios-xnu-userland/userland
cd $U
for _d in "$PWD/../../hackios-xnu-kernel/xnu-deps/host/bin" "$PWD/../xnu-deps/host/bin"; do
	[ -d "$_d" ] && PATH="$_d:$PATH"
done
THEOS=${THEOS:-$HOME/theos}
DRV=../../hackios-xnu-kernel/tools/userland-driver
[ -d "$DRV" ] || DRV=../tools/userland-driver
SRC_INC="-Isrc/boot -Isrc/inject -Isrc/gfx -Isrc/services -Isrc/apps -Isrc/tests -I$DRV"
DYN="xnu-clang -arch arm64 -isysroot ${THEOS}/sdks/iPhoneOS16.5.sdk -O1 $SRC_INC"

echo "=== compiling sbtrace ==="
$DYN -dynamiclib -framework CoreFoundation -framework IOKit -lobjc src/inject/sbtrace.c -o obj/libsbtrace.dylib 2>&1 | head -20
ls -la obj/libsbtrace.dylib

echo "=== signing ==="
if [ -z "$LDID" ] && ! command -v ldid >/dev/null 2>&1; then
	[ -x "${THEOS}/toolchain/linux/iphone/bin/ldid" ] && LDID=${THEOS}/toolchain/linux/iphone/bin/ldid
fi
${LDID:-ldid} -S obj/libsbtrace.dylib && echo signed

echo "=== into the ramdisk staging ==="
cp -f obj/libsbtrace.dylib /root/star26/s111/work/rootbuild/root/lib/libsbtrace.dylib
ls -la /root/star26/s111/work/rootbuild/root/lib/libsbtrace.dylib
strings -n 10 /root/star26/s111/work/rootbuild/root/lib/libsbtrace.dylib | grep -c 'a dictionary made here'
</bash>
