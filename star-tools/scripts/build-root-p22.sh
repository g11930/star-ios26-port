#!/bin/bash
# Swap the rebuilt driver into the release staging tree and rebuild root.apfs.
#
# libannibalemetal.dylib is a manifest root entry, not one of the 564 recipes: build-star26-root.py
# copies it straight out of RELEASE/root (line 105) without a digest check. The tree digest it
# prints will differ from the official one, and it will differ by exactly this file.
set -e
OLD=/root/star26/release/v0.1.3/hackios-k90-v0.1.3/root/lib/libannibalemetal.dylib
NEW=/root/star26/p22/libannibalemetal.dylib

echo "=== before ==="
md5sum "$OLD"

if [ ! -f "$OLD.v013" ]; then
	cp -f "$OLD" "$OLD.v013"
	echo "kept the release copy as libannibalemetal.dylib.v013"
fi
cp -f "$NEW" "$OLD"

echo "=== after ==="
md5sum "$OLD"

echo "=== rebuild root.apfs ==="
python3 /mnt/d/桌面/star26-deps/scripts/build-star26-root.py \
	--fw /root/star26/p2/fw --ipsw /root/star26/ipsw \
	--work /root/star26/p22/work --output /root/star26/p22/root.apfs 2>&1 | tail -25
