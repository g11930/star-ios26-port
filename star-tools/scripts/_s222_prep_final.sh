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
echo "=== mem now ==="
free -h | head -2
echo "PREP_DONE"
