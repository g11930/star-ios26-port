#!/bin/bash
SDK=/root/star26/hackios-xnu-userland/userland/xnu-deps/26/sdk/iPhoneOS.sdk
AV="$SDK/usr/include/os/availability.h"
echo "=== reconstructed os/availability.h 440-495 ==="
sed -n '440,495p' "$AV"
