#!/bin/bash
# Syntax-only check of the edited inject_sb26.c (we cannot produce a loadable arm64e dylib here,
# but we can prove the source still parses and type-checks).
cd /root/star26/hackios-xnu-userland/userland || exit 1
DRV=/root/star26/hackios-xnu-kernel/tools/userland-driver
SRC_INC="-I/tmp/ptrauth-stub -Isrc/boot -Isrc/inject -Isrc/gfx -Isrc/services -Isrc/apps -Isrc/tests -I$DRV"
export PATH=/root/star-build/xnu-deps/host/bin:$PATH
XNU_SDK_VERSION=26.0 xnu-clang -arch arm64e -isysroot /root/star26/hackios-xnu-userland/userland/xnu-deps/26/sdk/iPhoneOS.sdk \
  -miphoneos-version-min=26.0 -fsyntax-only -Os $SRC_INC \
  -framework CoreFoundation -framework Metal -lobjc -lMobileGestalt \
  src/inject/inject_sb26.c 2>&1 | head -30
echo "SYNTAX_EXIT=$?"
