#!/bin/bash
# P25: everything in the payload is P24's (kernel with the AnnibaleGPU stub, root.apfs with the
# patched libannibaleair that no longer asks softpipe for a shared buffer). The one change is the
# boot-arg fbscale=2: MiniIOMobileFramebuffer then draws 375x812 points at two pixels a point,
# 750x1624 instead of 1125x2436 -- 2.25 times fewer pixels for the processor to fill, and it also
# rewrites /chosen display-scale and /product artwork-scale-factor so MobileGestalt follows.
set -e
SRC=/root/star26/p24/src
DST=/root/star26/p25/src
mkdir -p "$DST"
cp -f "$SRC"/identity "$SRC"/loader.efi "$SRC"/memsize "$SRC"/rdimage "$SRC"/ramdisk "$DST"/

printf 'debug=0x10e rootdev=md0 root_apfs=ufs_darwin launchd_unsecure_cache=1 cpus=4 bootcpu=7 small_cores_after=0 ufs=2 ufs_native=1 ufs_write=1 loader_return_after=600 adreno8=2 adreno8_only=2 rwa_software=1 fbscale=2' > "$DST/cmdline"

sed -e 's#/root/star26/p24#/root/star26/p25#g' \
    -e 's#p24-payload#p25-payload#g' \
    -e 's#p24-boot#p25-boot#g' \
    /root/star26/p24/p24-pack.py > /root/star26/p25/p25-pack.py
chmod +x /root/star26/p25/p25-pack.py
cd /root/star26/p25
python3 p25-pack.py
echo "--- cmdline ---"; cat "$DST/cmdline"; echo
ls -la /root/star26/p25/p25-boot.img
sha256sum /root/star26/p25/p25-boot.img
