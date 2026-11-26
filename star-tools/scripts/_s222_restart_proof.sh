#!/bin/bash
set -e
SCRIPTS=/root/dsc26_zeta_scripts
PY=/root/star26/zeta-venv/bin/python
cp /mnt/d/桌面/star26-deps/work/zeta_scripts/prove-zeta-dyld-cache.py "$SCRIPTS/prove-zeta-dyld-cache.py"
echo "synced proof script"
# Verify the patch landed
grep -n 'pool_size=3\|def run(jobs, label, pool_size' "$SCRIPTS/prove-zeta-dyld-cache.py"
# Keep the 4116 first-round npz as backup, then start clean (full rerun needed for consistent summary)
echo "current npz: $(ls /root/dsc26_proof/*.npz 2>/dev/null | wc -l)"
echo "=== swap ==="
grep -i SwapTotal /proc/meminfo
echo "READY"
