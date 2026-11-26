#!/bin/bash
# P26: the P21 kernel (stub AnnibaleGPU service) unchanged; what changes is the compiler
# library in root.apfs. It is now built from Mesa 26.2.5 source with two changes:
#   * air_metal_lowering.inc: the softpipe half lowering covers the sampling tex ops, not
#     only txf, so the window server's half sampler pipeline is no longer refused;
#   * air_metal.c: no PIPE_BIND_SHARED on the software backend (P24's binary patch, now in
#     source), so buffers of a page or more allocate instead of asking a null winsys for a
#     display target.
set -e
AIR=/root/star26/p26/libannibaleair.dylib
STAGE=/root/star26/release/v0.1.3/hackios-k90-v0.1.3/root/lib/libannibaleair.dylib

echo "=== staging before ==="
md5sum "$STAGE"
if [ -f "$STAGE.v013" ]; then
	echo "pristine backup:"; md5sum "$STAGE.v013"
else
	cp -f "$STAGE" "$STAGE.v013"
	echo "pristine backup: $(md5sum "$STAGE.v013")"
fi
cp -f "$AIR" "$STAGE"
echo "=== staging after ==="
md5sum "$STAGE" "$AIR"

echo "=== root.apfs ==="
python3 /mnt/d/桌面/star26-deps/scripts/build-star26-root.py \
	--fw /root/star26/p2/fw --ipsw /root/star26/ipsw \
	--work /root/star26/p26/work --output /root/star26/p26/root.apfs 2>&1 | tail -12

echo "=== payload ==="
SRC=/root/star26/p22/src
DST=/root/star26/p26/src
mkdir -p "$DST"
cp -f "$SRC"/identity "$SRC"/loader.efi "$SRC"/memsize "$SRC"/rdimage "$DST"/
cp -f /root/star26/p26/root.apfs "$DST"/ramdisk

printf 'debug=0x10e rootdev=md0 root_apfs=ufs_darwin launchd_unsecure_cache=1 cpus=4 bootcpu=7 small_cores_after=0 ufs=2 ufs_native=1 ufs_write=1 loader_return_after=600 adreno8=2 adreno8_only=2 rwa_software=1' > "$DST/cmdline"

sed -e 's#/root/star26/p24#/root/star26/p26#g' \
    -e 's#p24-payload#p26-payload#g' \
    -e 's#p24-boot#p26-boot#g' \
    /root/star26/p24/p24-pack.py > /root/star26/p26/p26-pack.py
chmod +x /root/star26/p26/p26-pack.py
cd /root/star26/p26
python3 p26-pack.py
echo "--- cmdline ---"; cat "$DST/cmdline"; echo
ls -la /root/star26/p26/p26-boot.img
sha256sum /root/star26/p26/p26-boot.img
