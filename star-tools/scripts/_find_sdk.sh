#!/bin/bash
echo "=== candidate XNU SDKs ==="
for d in \
  /root/star-build/xnu-deps/sdk/iPhoneOS16.5.xnu.sdk \
  /root/star26/hackios-xnu-kernel/xnu-deps/sdk/iPhoneOS16.5.xnu.sdk \
  /root/star26/hackios-xnu-userland/xnu-deps/26/sdk/iPhoneOS.sdk ; do
  if [ -d "$d" ]; then
    echo "EXISTS: $d"
    ls "$d/System/Library/Frameworks/CoreFoundation.framework/Headers/CoreFoundation.h" 2>/dev/null && echo "  CF header OK"
    grep -m1 -E 'CLANG18_NOOP|#if 0' "$d/usr/include/Availability.h" 2>/dev/null | sed 's/^/  Availability: /'
    grep -m1 -E '#define API_AVAILABLE' "$d/usr/include/os/availability.h" 2>/dev/null | sed 's/^/  os/availability: /'
  else
    echo "MISSING: $d"
  fi
done
echo "=== xnu-clang version / underlying clang ==="
/root/star26/hackios-xnu-kernel/xnu-deps/host/bin/xnu-clang --version 2>&1 | head -3
echo "=== xnu-clang wrapper content ==="
head -30 /root/star26/hackios-xnu-kernel/xnu-deps/host/bin/xnu-clang 2>/dev/null
