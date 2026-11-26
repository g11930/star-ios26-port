#!/bin/bash
set -e
W=/root/star26/star-native
S="$W/osfmk/arm64/sleh.c"
echo "=== current hash ==="
md5sum "$S"
cd "$W"
git log -1 --format='%h %ad %s' --date=short
echo "=== backup ==="
cp "$S" "$S.s221-pre-rewrite"
md5sum "$S.s221-pre-rewrite"
echo "=== copy to windows ==="
mkdir -p /mnt/d/桌面/star26-deps/work
cp "$S" /mnt/d/桌面/star26-deps/work/sleh.c.s221
echo "=== PAC symbol count ==="
grep -c "pac_" "$S"
echo "DONE"
