#!/bin/bash
SDK=/root/star26/hackios-xnu-userland/userland/xnu-deps/26/sdk/iPhoneOS.sdk
XC=/root/star26/hackios-xnu-kernel/xnu-deps/host/bin/xnu-clang

echo "=== [1] SDK root ==="
ls -la "$SDK" 2>&1 | head -20
echo "--- System symlink target ---"
readlink -f "$SDK/System" 2>&1

echo ""
echo "=== [2] required headers (build.sh guard checks CoreFoundation) ==="
for h in \
  System/Library/Frameworks/CoreFoundation.framework/Headers/CoreFoundation.h \
  System/Library/Frameworks/Metal.framework/Headers/Metal.h \
  System/Library/Frameworks/Foundation.framework/Headers/Foundation.h \
 usr/include/objc/objc.h \
  usr/lib/libobjc.tbd; do
  if [ -e "$SDK/$h" ]; then echo "  OK   $h"; else echo "  MISS $h"; fi
done

echo ""
echo "=== [3] xnu-clang content ==="
cat "$XC" 2>&1 | head -80

echo ""
echo "=== [4] XNU_SDK_VERSION=26 handling ==="
grep -n -E "XNU_SDK_VERSION|26|arm64e|pac|branch-protection|isysroot|SDKROOT" "$XC" 2>/dev/null | head -40

echo ""
echo "=== [5] xnu-clang version ==="
XNU_SDK_VERSION=26.0 "$XC" --version 2>&1 | head -6
