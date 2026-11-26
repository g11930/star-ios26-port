#!/bin/bash
# P19: P18 (softpipe registration, proven working in backboardd) plus the one thing
# SpringBoard was missing: ANNIBALE_SB_METAL=1 in its environment. Its launchd job does
# not carry the switch, so run_sequence() skipped registration ("switch=unset"); the
# kernel now adds the same variable as RWA_SOFTWARE for the programs inject.conf names.
set -e

SRC=/root/star26/p18/src
DST=/root/star26/p19/src
mkdir -p "$DST"
cp -f "$SRC"/identity "$SRC"/loader.efi "$SRC"/memsize "$SRC"/rdimage "$SRC"/ramdisk "$DST"/

printf 'debug=0x10e rootdev=md0 root_apfs=ufs_darwin launchd_unsecure_cache=1 cpus=4 bootcpu=7 small_cores_after=0 ufs=2 ufs_native=1 ufs_write=1 loader_return_after=600 adreno8=2 adreno8_only=2 rwa_software=1' > "$DST/cmdline"

sed -e 's#/root/star26/p18#/root/star26/p19#g' \
    -e 's#p18-payload#p19-payload#g' \
    -e 's#p18-boot#p19-boot#g' \
    /root/star26/p18/p18-pack.py > /root/star26/p19/p19-pack.py
chmod +x /root/star26/p19/p19-pack.py
cd /root/star26/p19
python3 p19-pack.py
echo "--- cmdline ---"; cat "$DST/cmdline"; echo
ls -la /root/star26/p19/p19-boot.img
sha256sum /root/star26/p19/p19-boot.img
