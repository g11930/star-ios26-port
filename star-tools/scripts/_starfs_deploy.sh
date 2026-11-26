#!/bin/bash
# Deploy the rebuilt starfs KernelSU module to the phone via the manual path
# (adb push -> su cp), because ksud module install fails on this device with a UAPI
# mismatch between the running kernel and the shipped ksud binary.
export MSYS_NO_PATHCONV=1
A=/mnt/d/桌面/adb-fastboot/adb.exe
SRC=/mnt/d/桌面/star26-deps/module/starfs/build
STAGE=/mnt/c/ios26/starfs-mod
DEV=/data/local/tmp/starfs-mod

echo "=== adb ==="
"$A" start-server >/dev/null 2>&1
sleep 1
"$A" devices 2>&1 | tr -d '\r'

echo "=== root ==="
"$A" shell "su -c id" 2>&1 | tr -d '\r'

echo "=== stage locally ==="
rm -rf "$STAGE"
mkdir -p "$STAGE"
cp -r "$SRC"/. "$STAGE"/
find "$STAGE" -type f | sed "s|$STAGE/||" | sort

echo "=== push ==="
"$A" shell "rm -rf $DEV" 2>&1 | tr -d '\r'
# adb.exe is a Windows binary: it cannot resolve WSL paths such as /mnt/c/..., so the
# source has to be handed over as a Windows path.
"$A" push "C:/ios26/starfs-mod" /data/local/tmp/ 2>&1 | tr -d '\r' | tail -2

echo "=== install.sh on device ==="
"$A" shell "su -c 'sh $DEV/install.sh'" 2>&1 | tr -d '\r'

echo "=== verify module tree ==="
"$A" shell "su -c 'ls -la /data/adb/modules/starfs; echo ---; cat /data/adb/modules/starfs/module.prop'" 2>&1 | tr -d '\r'

echo "=== verify command on PATH ==="
"$A" shell "su -c 'command -v starfs; starfs root'" 2>&1 | tr -d '\r'

echo "=== verify pending-update leftovers ==="
"$A" shell "su -c 'ls -d /data/adb/modules_update/starfs 2>/dev/null || echo none'" 2>&1 | tr -d '\r'
echo "=== DONE ==="
