#!/bin/bash
set -e
echo "=== sync patched scripts ==="
cp /mnt/d/桌面/star26-deps/work/zeta_scripts/zeta_userland_code.py /root/dsc26_zeta_scripts/zeta_userland_code.py
cp /mnt/d/桌面/star26-deps/work/zeta_scripts/prove-zeta-dyld-cache.py /root/dsc26_zeta_scripts/prove-zeta-dyld-cache.py
cd /root/dsc26_zeta_scripts
grep -n 'CHUNK = 2048' zeta_userland_code.py
grep -n 'pool_size=8\|pool_size=3' prove-zeta-dyld-cache.py
echo "=== swap status (should be 2G) ==="
grep -i SwapTotal /proc/meminfo
echo "=== fresh proof dir ==="
rm -rf /root/dsc26_proof
mkdir -p /root/dsc26_proof
free -h | head -2
echo "PREP_V4_DONE"
