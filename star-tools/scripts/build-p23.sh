#!/bin/bash
# P23: same kernel as P21/P22 (the stub AnnibaleGPU service), but the driver library rebuilt for
# arm64e so that it can actually be dlopen'd into SpringBoard and backboardd.
#
# P22 (arm64) proved the stub answers correctly -- no drawable fell from dozens to zero -- but the
# library itself never loaded: dlopen refused it as "incompatible architecture (have 'arm64', need
# 'arm64e')", the Metal device stayed nil, and the window server logged "Failed to initialize Metal
# or OpenGLES contexts!" with the boot overlay frozen at 40%.
set -e

SRC=/root/star26/p22/src
DST=/root/star26/p23/src
mkdir -p "$DST"
cp -f "$SRC"/identity "$SRC"/loader.efi "$SRC"/memsize "$SRC"/rdimage "$DST"/
cp -f /root/star26/p23/root.apfs "$DST"/ramdisk

printf 'debug=0x10e rootdev=md0 root_apfs=ufs_darwin launchd_unsecure_cache=1 cpus=4 bootcpu=7 small_cores_after=0 ufs=2 ufs_native=1 ufs_write=1 loader_return_after=600 adreno8=2 adreno8_only=2 rwa_software=1' > "$DST/cmdline"

sed -e 's#/root/star26/p22#/root/star26/p23#g' \
    -e 's#p22-payload#p23-payload#g' \
    -e 's#p22-boot#p23-boot#g' \
    /root/star26/p22/p22-pack.py > /root/star26/p23/p23-pack.py
chmod +x /root/star26/p23/p23-pack.py
cd /root/star26/p23
python3 p23-pack.py
echo "--- cmdline ---"; cat "$DST/cmdline"; echo
ls -la /root/star26/p23/p23-boot.img
sha256sum /root/star26/p23/p23-boot.img
