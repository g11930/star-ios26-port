#!/bin/bash
echo "=== killing deadlocked proof workers ==="
pids=$(pgrep -f 'zeta-venv/bin/python prove-zeta-dyld-cache.py')
for p in $pids; do
  kill -9 "$p" 2>/dev/null && echo "killed $p"
done
sleep 2
echo "=== remaining proof processes ==="
pgrep -af 'prove-zeta-dyld-cache.py' || echo "none"
echo "=== npz preserved ==="
ls /root/dsc26_proof/*.npz 2>/dev/null | wc -l
