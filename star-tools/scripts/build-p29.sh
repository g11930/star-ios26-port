#!/bin/bash
# P29: P28's kernel (the two probes stay: they cost nothing and name the next crash),
# P28's cmdline, and a rebuilt libannibaleair.dylib whose demote_half_alu no longer
# swaps an instruction's sources by hand.
set -e

AIR=/root/star26/p29/libannibaleair.dylib
STAGE=/root/star26/release/v0.1.3/hackios-k90-v0.1.3/root/lib/libannibaleair.dylib
LOG=/root/star26/p29/build.log
: > "$LOG"

echo "=== staging before ===" | tee -a "$LOG"
md5sum "$STAGE" | tee -a "$LOG"
if [ -f "$STAGE.v013" ]; then
	echo "pristine backup: $(md5sum "$STAGE.v013")" | tee -a "$LOG"
else
	cp -f "$STAGE" "$STAGE.v013"
	echo "pristine backup made: $(md5sum "$STAGE.v013")" | tee -a "$LOG"
fi
cp -f "$AIR" "$STAGE"
echo "=== staging after ===" | tee -a "$LOG"
md5sum "$STAGE" "$AIR" | tee -a "$LOG"

echo "=== root.apfs ===" | tee -a "$LOG"
python3 /mnt/d/桌面/star26-deps/scripts/build-star26-root.py \
	--fw /root/star26/p2/fw --ipsw /root/star26/ipsw \
	--work /root/star26/p29/work --output /root/star26/p29/root.apfs 2>&1 | tail -12 | tee -a "$LOG"

echo "=== payload ===" | tee -a "$LOG"
SRC=/root/star26/p22/src
DST=/root/star26/p29/src
mkdir -p "$DST"
cp -f "$SRC"/identity "$SRC"/loader.efi "$SRC"/memsize "$SRC"/rdimage "$DST"/
cp -f /root/star26/p29/root.apfs "$DST"/ramdisk
printf 'debug=0x10e rootdev=md0 root_apfs=ufs_darwin launchd_unsecure_cache=1 cpus=4 bootcpu=7 small_cores_after=0 ufs=2 ufs_native=1 ufs_write=1 loader_return_after=420 adreno8=2 adreno8_only=2 rwa_software=1' > "$DST"/cmdline

sed -e 's#/root/star26/p24#/root/star26/p29#g' \
    -e 's#p24-payload#p29-payload#g' \
    -e 's#p24-boot#p29-boot#g' \
    /root/star26/p24/p24-pack.py > /root/star26/p29/p29-pack.py
chmod +x /root/star26/p29/p29-pack.py
cd /root/star26/p29
python3 p29-pack.py 2>&1 | tee -a "$LOG"

echo "--- cmdline ---" | tee -a "$LOG"
cat "$DST/cmdline" | tee -a "$LOG"
echo | tee -a "$LOG"
ls -la /root/star26/p29/p29-boot.img | tee -a "$LOG"
sha256sum /root/star26/p29/p29-boot.img | tee -a "$LOG"
