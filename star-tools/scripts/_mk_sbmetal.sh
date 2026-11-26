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
SRC_INC="-Isrc/boot -Isrc/inject -Isrc/gfx -Isrc/services -Isrc/apps -Isrc/tests -I$DRV -I/mnt/d/桌面/star26-deps/scripts/compat"
DYN="xnu-clang -arch arm64e -isysroot ${THEOS}/sdks/iPhoneOS16.5.sdk -O1 $SRC_INC"

echo "=== compiling libannibale-sbmetal-experiment ==="
$DYN -dynamiclib -install_name /annibale/lib/libannibale-sbmetal-experiment.dylib \
	-fno-objc-arc -Wl,-undefined,dynamic_lookup -framework Foundation -framework Metal -framework UIKit -framework IOKit -lobjc \
	src/inject/sb_metal_experiment.m -o obj/libannibale-sbmetal-experiment.dylib 2>&1 | head -30
ls -la obj/libannibale-sbmetal-experiment.dylib

if [ -z "$LDID" ] && ! command -v ldid >/dev/null 2>&1; then
	[ -x "${THEOS}/toolchain/linux/iphone/bin/ldid" ] && LDID=${THEOS}/toolchain/linux/iphone/bin/ldid
fi
${LDID:-ldid} -S obj/libannibale-sbmetal-experiment.dylib && echo signed

cp -f obj/libannibale-sbmetal-experiment.dylib /root/star26/s111/work/rootbuild/root/lib/libannibale-sbmetal-experiment.dylib
ls -la /root/star26/s111/work/rootbuild/root/lib/libannibale-sbmetal-experiment.dylib
strings -n 6 /root/star26/s111/work/rootbuild/root/lib/libannibale-sbmetal-experiment.dylib | grep -c 'backend mismatch'
