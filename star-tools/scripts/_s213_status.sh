#!/bin/bash
echo "=== SDK cleanliness (should have NO .finalbak213/.fixbak213/.minbak213/.orig213 leftovers) ==="
find /root/theos/sdks/iPhoneOS16.5.sdk /root/star26/hackios-xnu-userland/userland/xnu-deps/26/sdk -name '*.213*' -o -name '*.s213bak' 2>/dev/null | head -20
echo "=== current Availability.h first line (theos) ==="
head -1 /root/theos/sdks/iPhoneOS16.5.sdk/usr/include/Availability.h
echo "=== reconstructed SDK availability markers ==="
grep -m1 'CLANG18_NOOP' /root/star26/hackios-xnu-userland/userland/xnu-deps/26/sdk/iPhoneOS.sdk/usr/include/Availability.h
echo "=== source patch status ==="
cd /root/star26/hackios-xnu-userland/userland/src/inject
grep -n 'UNLOCK_SOURCE_COVER_SHEET\|waiting for CoverSheet\|state == 2 ||' inject_sb26.c | head
echo "=== current dylib (should still be OLD, md5 69bcfa3c) ==="
md5sum /root/star26/hackios-xnu-userland/userland/obj/libannibale-sb26.dylib
