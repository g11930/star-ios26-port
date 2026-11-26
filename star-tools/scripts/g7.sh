#!/bin/bash
set -u
echo "=== rootbuild root/LaunchDaemons (SpringBoard) ==="
ls /root/star26/p38/work/rootbuild/root/LaunchDaemons/ | head -20
echo "=== SpringBoard plist ==="
cat /root/star26/p38/work/rootbuild/root/LaunchDaemons/com.apple.SpringBoard.plist 2>/dev/null
echo "=== mkjobs OSLOG logic ==="
grep -n "OSLOG\|oslog\|os_log\|StandardError\|stderr" /root/star26/hackios-xnu-userland/userland/mkjobs.py | head -40
