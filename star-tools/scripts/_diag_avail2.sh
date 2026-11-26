#!/bin/bash
AV=/root/theos/sdks/iPhoneOS16.5.sdk/usr/include/os/availability.h
echo "=== theos 16.5 availability.h 130-170 ==="
sed -n '130,170p' "$AV"
echo
echo "=== reconstructed SDK availability.h 130-170 ==="
sed -n '130,170p' /root/star26/hackios-xnu-userland/userland/xnu-deps/26/sdk/iPhoneOS.sdk/usr/include/os/availability.h
