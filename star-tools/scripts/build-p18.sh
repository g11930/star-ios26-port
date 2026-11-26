#!/bin/bash
# P18: the software-rendering experiment.
#
# Two changes, both ours:
#   1. root/lib/libannibale-sbmetal-experiment.dylib now expects the backend name
#      "softpipe" instead of "Adreno (TM) 830" (a 16-byte string patch: the compiled
#      literal is exactly 16 bytes with its NUL, so nothing moves).
#   2. the kernel adds RWA_SOFTWARE=1 to the environment of the programs etc/inject.conf
#      names, when the boot arguments say rwa_software=1. libannibaleair reads that
#      variable at rwa_device_open and takes its software rasterizer (softpipe) instead
#      of opening the Adreno through the msm shim, which on star does not exist.
#
# Together they let SpringBoard register a Metal device backed by softpipe, i.e. a
# window server that draws on the processor. No kernel GPU driver is involved.
set -e

SRC=/root/star26/p17/src
DST=/root/star26/p18/src
mkdir -p "$DST"
cp -f "$SRC"/identity "$SRC"/loader.efi "$SRC"/memsize "$SRC"/rdimage "$DST"/
cp -f /root/star26/p18/root.apfs "$DST"/ramdisk

printf 'debug=0x10e rootdev=md0 root_apfs=ufs_darwin launchd_unsecure_cache=1 cpus=4 bootcpu=7 small_cores_after=0 ufs=2 ufs_native=1 ufs_write=1 loader_return_after=600 adreno8=2 adreno8_only=2 rwa_software=1' > "$DST/cmdline"

sed -e 's#/root/star26/p17#/root/star26/p18#g' \
    -e 's#p17-payload#p18-payload#g' \
    -e 's#p17-boot#p18-boot#g' \
    /root/star26/p17/p17-pack.py > /root/star26/p18/p18-pack.py
chmod +x /root/star26/p18/p18-pack.py
cd /root/star26/p18
python3 p18-pack.py
echo "--- cmdline ---"
cat "$DST/cmdline"; echo
wc -c < "$DST/cmdline"
ls -la /root/star26/p18/p18-boot.img
sha256sum /root/star26/p18/p18-boot.img
