#!/bin/bash
echo "=== md5 of every loader.c ==="
md5sum /root/star-build/xnuloader/loader.c \
       /root/star26/hackios-xnu-kernel/xnuloader/loader.c \
       /root/k90-src/xnuloader/loader.c 2>/dev/null
md5sum "/mnt/d/桌面/star-ios16-stable-documented-20261030/.workbuddy/wsl/loader/loader.c"

echo
echo "=== star26 xnuloader contents ==="
ls -la /root/star26/hackios-xnu-kernel/xnuloader/ | head -25

echo
echo "=== loader.efi sizes ==="
for f in /root/star-build/xnuloader/loader.efi /root/star26/hackios-xnu-kernel/xnuloader/loader.efi; do
  [ -f "$f" ] && echo "$(stat -c%s "$f") $f"
done

echo
echo "=== which loader.efi is inside the s96 image? ==="
ls -la /mnt/c/ios26/*.img 2>/dev/null | tail -5

echo
echo "=== efi.h system table region ==="
sed -n '80,105p' /root/star26/hackios-xnu-kernel/xnuloader/efi.h

echo
echo "=== loader.c line count both ==="
wc -l /root/star-build/xnuloader/loader.c /root/star26/hackios-xnu-kernel/xnuloader/loader.c
