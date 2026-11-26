#!/bin/bash
cd /root/star26/hackios-xnu-kernel/userland 2>/dev/null || cd /root/star26/hackios-xnu-userland/userland
which xnu-clang; ls ../xnu-deps/26/sdk/iPhoneOS.sdk 2>/dev/null | head -3
echo "=== try a compile of the shim (no link) ==="
XNU_SDK_VERSION=26.0 xnu-clang -arch arm64e -isysroot ../xnu-deps/26/sdk/iPhoneOS.sdk \
  -miphoneos-version-min=26.0 -O1 -I../tools/userland-driver -I../tools -I../xnu-deps/26/sdk/iPhoneOS.sdk/usr/include \
  -fsyntax-only ../tools/userland-driver/annibalemetal.m 2>&1 | head -6
echo "exit=$?"
</>
