#!/bin/bash
# P17: same payload as P16 but with a kernel that carries the star port probe.
# adreno8_step_gpucc() (step 2, documented read-only) now also reads, at
# lahaina's own addresses:
#   gpucc+0x1106c  qcom,gdsc@3d9106c  gpu_cc_cx_gdsc
#   gpucc+0x1100c  qcom,gdsc@3d9100c  gpu_cc_gx_gdsc
#   0x3d6a000+0..12  qcom,gmu@3d69000  kgsl_gmu_reg front room
#   0x3d00000+0/4    GPU wrapper identity words
# Everything else is untouched: step 1 stays skipped (QFPROM lives at 0x784000
# on star, not 0x221c8138), and no write path is reachable with adreno8_only=2.
set -e

SRC=/root/star26/p16/src
DST=/root/star26/p17/src
mkdir -p "$DST"
cp -f "$SRC"/identity "$SRC"/loader.efi "$SRC"/memsize "$SRC"/ramdisk "$SRC"/rdimage "$DST"/

printf 'debug=0x10e rootdev=md0 root_apfs=ufs_darwin launchd_unsecure_cache=1 cpus=4 bootcpu=7 small_cores_after=0 ufs=2 ufs_native=1 ufs_write=1 loader_return_after=240 adreno8=2 adreno8_only=2' > "$DST/cmdline"

sed -e 's#/root/star26/p16#/root/star26/p17#g' \
    -e 's#p16-payload#p17-payload#g' \
    -e 's#p16-boot#p17-boot#g' \
    /root/star26/p16/p16-pack.py > /root/star26/p17/p17-pack.py
chmod +x /root/star26/p17/p17-pack.py
cd /root/star26/p17
python3 p17-pack.py
echo "--- cmdline ---"
cat "$DST/cmdline"; echo
wc -c < "$DST/cmdline"
ls -la /root/star26/p17/p17-boot.img
sha256sum /root/star26/p17/p17-boot.img
