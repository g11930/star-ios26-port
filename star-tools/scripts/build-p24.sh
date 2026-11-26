#!/bin/bash
# P24: the P23 kernel (the stub AnnibaleGPU service) unchanged; what changes is the compiler library
# in root.apfs. softpipe refused every buffer of a page or more because rwa_buffer_create asked for
# PIPE_BIND_SHARED and null_sw_winsys never makes a display target -- patch-air-p24.sh cleared that
# one instruction. Everything else in the payload is P23's, so the only variable is the library.
set -e
AIR=/root/star26/p24/libannibaleair.dylib
STAGE=/root/star26/release/v0.1.3/hackios-k90-v0.1.3/root/lib/libannibaleair.dylib

echo "=== staging before ==="
md5sum "$STAGE"
[ -f "$STAGE.v013" ] || cp -f "$STAGE" "$STAGE.v013"
cp -f "$AIR" "$STAGE"
echo "=== staging after ==="
md5sum "$STAGE" "$AIR"

python3 /mnt/d/桌面/star26-deps/scripts/build-star26-root.py \
	--fw /root/star26/p2/fw --ipsw /root/star26/ipsw \
	--work /root/star26/p24/work --output /root/star26/p24/root.apfs 2>&1 | tail -12

echo "=== payload ==="
SRC=/root/star26/p22/src
DST=/root/star26/p24/src
mkdir -p "$DST"
cp -f "$SRC"/identity "$SRC"/loader.efi "$SRC"/memsize "$SRC"/rdimage "$DST"/
cp -f /root/star26/p24/root.apfs "$DST"/ramdisk

printf 'debug=0x10e rootdev=md0 root_apfs=ufs_darwin launchd_unsecure_cache=1 cpus=4 bootcpu=7 small_cores_after=0 ufs=2 ufs_native=1 ufs_write=1 loader_return_after=600 adreno8=2 adreno8_only=2 rwa_software=1' > "$DST/cmdline"

sed -e 's#/root/star26/p23#/root/star26/p24#g' \
    -e 's#p23-payload#p24-payload#g' \
    -e 's#p23-boot#p24-boot#g' \
    /root/star26/p23/p23-pack.py > /root/star26/p24/p24-pack.py
chmod +x /root/star26/p24/p24-pack.py
cd /root/star26/p24
python3 p24-pack.py
echo "--- cmdline ---"; cat "$DST/cmdline"; echo
ls -la /root/star26/p24/p24-boot.img
sha256sum /root/star26/p24/p24-boot.img
