#!/bin/bash
SDK=/root/star26/hackios-xnu-userland/userland/xnu-deps/26/sdk/iPhoneOS.sdk
AV="$SDK/usr/include/Availability.h"
echo "=== reconstructed Availability.h 440-490 ==="
sed -n '440,490p' "$AV"
