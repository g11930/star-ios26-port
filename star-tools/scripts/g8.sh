#!/bin/bash
set -u
P=/root/star26/p30
echo "=== p30 work ==="
ls -la $P/work 2>/dev/null
echo "=== p30 rootbuild root (top) ==="
ls -la $P/work/rootbuild/root 2>/dev/null | head -25
echo "=== LaunchDaemons count ==="
ls $P/work/rootbuild/root/LaunchDaemons 2>/dev/null | wc -l
echo "=== SpringBoard plist present? ==="
ls -la $P/work/rootbuild/root/LaunchDaemons/com.apple.SpringBoard.plist 2>/dev/null
echo "=== mkapfs help ==="
python3 /root/star26/hackios-xnu-userland/tools/apfs/mkapfs.py --help 2>&1 | head -25
echo "=== apfsck? ==="
ls /root/star26/hackios-xnu-userland/tools/apfs/ 2>/dev/null
