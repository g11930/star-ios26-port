#!/bin/bash
set -e
S=/root/star26/hackios-xnu-userland/userland/src/inject/inject_sb26.c
echo "=== 1) backup inject_sb26.c ==="
cp -f "$S" "$S.s95-pre-xpc.bak"
md5sum "$S" "$S.s95-pre-xpc.bak"
echo "=== 2) backup s94 ramdisk + root.apfs ==="
ls -la /root/star26/s94/parts/ramdisk
if [ -f /root/star26/s94/root.apfs ]; then
  cp -f /root/star26/s94/root.apfs /root/star26/s94/root.apfs.s95-pre-xpc.bak
  echo "root.apfs backed up"
else
  echo "no root.apfs in s94 (will need extraction from ramdisk)"
fi
cp -f /root/star26/s94/parts/ramdisk /root/star26/s94/parts/ramdisk.s95-pre-xpc.bak
echo "ramdisk backed up"
echo "=== 3) backup current built dylib ==="
find /root/star26/hackios-xnu-userland -name 'libannibale-sb26.dylib' -exec ls -la {} \; 2>/dev/null
find /root/star26/hackios-xnu-userland -name 'libannibale-sb26.dylib' -exec cp -f {} {}.s95-pre-xpc.bak \; 2>/dev/null
echo "=== DONE backup ==="
