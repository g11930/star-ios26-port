#!/bin/bash
# Put the arm64e driver into the release staging tree and rebuild root.apfs for P23.
set -e
OLD=/root/star26/release/v0.1.3/hackios-k90-v0.1.3/root/lib/libannibalemetal.dylib
NEW=/root/star26/p23/libannibalemetal.dylib

echo "=== staging before ==="
md5sum "$OLD"
if [ ! -f "$OLD.v013" ]; then
	cp -f "$OLD" "$OLD.v013"
fi
cp -f "$NEW" "$OLD"
echo "=== staging after ==="
md5sum "$OLD" "$NEW"

python3 /mnt/d/桌面/star26-deps/scripts/build-star26-root.py \
	--fw /root/star26/p2/fw --ipsw /root/star26/ipsw \
	--work /root/star26/p23/work --output /root/star26/p23/root.apfs 2>&1 | tail -20
