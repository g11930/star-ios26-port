#!/bin/bash
# P16: identical kernel/payload to P15, only the cmdline grows two boot-args:
#   adreno8=2       run the Adreno stepper up to step 2
#   adreno8_only=2  run only step 2 (GPUCC read-only probe); step 1 is skipped because
#                   it reads QFPROM 0x221c8138, which on star lives at 0x00784000 and
#                   would be an unmapped SError.
# Step 2 performs no writes: it reads GPUCC_CX_GDSCR and friends at 0x3d90000 and
# reports "all ones" if the clock controller does not answer.
set -e

SRC=/root/star26/p15/src
DST=/root/star26/p16/src
mkdir -p "$DST"
cp -f "$SRC"/identity "$SRC"/loader.efi "$SRC"/memsize "$SRC"/ramdisk "$SRC"/rdimage "$DST"/

printf 'debug=0x10e rootdev=md0 root_apfs=ufs_darwin launchd_unsecure_cache=1 cpus=4 bootcpu=7 small_cores_after=0 ufs=2 ufs_native=1 ufs_write=1 loader_return_after=600 adreno8=2 adreno8_only=2' > "$DST/cmdline"

sed -e 's#/root/star26/p15#/root/star26/p16#g' \
    -e 's#p14-payload#p16-payload#g' \
    -e 's#p14-boot#p16-boot#g' \
    /root/star26/p15/p15-pack.py > /root/star26/p16/p16-pack.py
chmod +x /root/star26/p16/p16-pack.py
cd /root/star26/p16
python3 p16-pack.py
echo "--- cmdline ---"
cat "$DST/cmdline"; echo
wc -c < "$DST/cmdline"
ls -la /root/star26/p16/p16-boot.img
