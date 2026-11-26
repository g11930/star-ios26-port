#!/bin/bash
set -e
echo "=== disable big swapfile (back to original 2G) ==="
swapoff /root/swapfile_proof 2>/dev/null || true
grep -i SwapTotal /proc/meminfo
echo "=== fresh proof dir ==="
rm -rf /root/dsc26_proof
mkdir -p /root/dsc26_proof
echo "=== verify script patch ==="
grep -n 'pool_size=3\|def run(jobs, label, pool_size' /root/dsc26_zeta_scripts/prove-zeta-dyld-cache.py
echo "=== start ==="
cd /root/dsc26_zeta_scripts
nohup /root/star26/zeta-venv/bin/python prove-zeta-dyld-cache.py \
  --cache /root/dsc26/System/Library/Caches/com.apple.dyld/dyld_shared_cache_arm64e \
  --work /root/dsc26_proof --jobs 16 > /root/proof_v3.log 2>&1 &
echo "PID=$!"
