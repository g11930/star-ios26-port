#!/bin/bash
# Rebuild the iOS26 SDK the way build.sh expects, from theos 16.5 SDK.
set -e
TARGET=/root/star26/hackios-xnu-userland/xnu-deps/26/sdk/iPhoneOS.sdk
SRC=/root/theos/sdks/iPhoneOS16.5.sdk
rm -rf /root/star26/hackios-xnu-userland/xnu-deps/26/sdk
mkdir -p /root/star26/hackios-xnu-userland/xnu-deps/26
cp -rs "$SRC" "$(dirname "$TARGET")" 2>/dev/null || cp -rs "$SRC" /root/star26/hackios-xnu-userland/xnu-deps/26/sdk
# cp -rs SRC DEST creates DEST/iPhoneOS16.5.sdk; rename if needed
if [ ! -d "$TARGET" ] && [ -d "$(dirname "$TARGET")/iPhoneOS16.5.sdk" ]; then
  mv "$(dirname "$TARGET")/iPhoneOS16.5.sdk" "$TARGET"
fi
echo "=== target ==="
ls -la "$TARGET" | head -6
echo "=== required header ==="
ls "$TARGET/System/Library/Frameworks/CoreFoundation.framework/Headers/CoreFoundation.h" && echo HEADER_OK
# Patch Availability.h so API_AVAILABLE is a no-op for stock clang 18
AV="$TARGET/usr/include/Availability.h"
cp -f "$AV" "$AV.stock" 2>/dev/null || true
python3 - "$AV" <<'PY'
import sys
p=sys.argv[1]
s=open(p).read()
# Insert a hard no-op override right before the first #define of API_AVAILABLE
marker='#define API_AVAILABLE'
idx=s.find(marker)
if idx<0:
    print('no API_AVAILABLE define found'); raise SystemExit
# Add override after the include guard's initial #define area, right before marker
override='''#ifndef __STOCK_CLANG_NOOP_AVAILABILITY
#define __STOCK_CLANG_NOOP_AVAILABILITY 1
#undef API_AVAILABLE
#undef API_UNAVAILABLE
#undef API_DEPRECATED
#undef API_DEPRECATED_WITH_REPLACEMENT
#define API_AVAILABLE(...)
#define API_UNAVAILABLE(...)
#define API_DEPRECATED(...)
#define API_DEPRECATED_WITH_REPLACEMENT(...)
#endif
'''
s=s[:idx]+override+s[idx:]
open(p,'w').write(s)
print('patched',p)
PY
echo "=== verify ==="
grep -n "STOCK_CLANG_NOOP_AVAILABILITY" "$AV" | head -3
