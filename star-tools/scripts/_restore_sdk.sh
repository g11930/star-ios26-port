#!/bin/bash
SDK=/root/star26/hackios-xnu-userland/userland/xnu-deps/26/sdk/iPhoneOS.sdk
echo "before md5:"
md5sum "$SDK/usr/include/os/availability.h" "$SDK/usr/include/os/availability.h.s213bak" 2>&1
cp -f "$SDK/usr/include/os/availability.h.s213bak" "$SDK/usr/include/os/availability.h"
cp -f "$SDK/usr/include/Availability.h.s213bak" "$SDK/usr/include/Availability.h"
echo "after restore:"
md5sum "$SDK/usr/include/os/availability.h" "$SDK/usr/include/os/availability.h.s213bak" 2>&1
echo "availability patch markers:"
grep -m1 -E '#if 0|CLANG18' "$SDK/usr/include/Availability.h" 2>/dev/null
grep -m1 -E '#if 0|define API_AVAILABLE' "$SDK/usr/include/os/availability.h" 2>/dev/null
