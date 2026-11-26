#!/bin/bash
set -e
SRC=/mnt/d/桌面/star26-deps/work/zeta_scripts
DST=/root/dsc26_zeta_scripts
for s in rewrite-zeta-dyld-cache.py rewrite-zeta-userland.py make-zeta-trust-bundle.py; do
  cp "$SRC/$s" "$DST/$s"
  echo "synced $s  size=$(stat -c%s "$DST/$s")"
done
# also sync the two trust caches into WSL work dir
mkdir -p /root/dsc26_work
cp /mnt/d/桌面/star26-deps/work/trust_static.im4p /root/dsc26_work/trust_static.im4p
cp /mnt/d/桌面/star26-deps/work/trust_systemcrytex.im4p /root/dsc26_work/trust_systemcrytex.im4p
echo "trust caches synced"
ls -la /root/dsc26_work/
