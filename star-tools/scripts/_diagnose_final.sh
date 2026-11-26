#!/bin/bash
T=/root/theos/sdks/iPhoneOS16.5.sdk
R=/root/star26/hackios-xnu-userland/userland/xnu-deps/26/sdk/iPhoneOS.sdk
echo "=== __OSX_AVAILABLE_STARTING definition: theos vs reconstructed ==="
for f in "$T/usr/include/Availability.h" "$R/usr/include/Availability.h"; do
  echo "--- $f ---"
  grep -n 'define __OSX_AVAILABLE_STARTING' "$f" | head
done
echo "=== sys/time.h diff (theos vs reconstructed) first差异 ==="
diff "$T/usr/include/sys/time.h" "$R/usr/include/sys/time.h" 2>/dev/null | head -30
echo "=== md5 sys/time.h ==="
md5sum "$T/usr/include/sys/time.h" "$R/usr/include/sys/time.h"
echo "=== theos Availability.h 195-225 (__OSX_AVAILABLE_STARTING body) ==="
sed -n '195,225p' "$T/usr/include/Availability.h"
