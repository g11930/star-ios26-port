#!/bin/bash
# P20: P19's experiment (softpipe Metal device in SpringBoard and backboardd) with the
# patched injection library re-signed ad hoc. Changing the backend-name literal
# invalidated the original CodeDirectory; a process carrying an invalid page hash is
# treated as not signed, which is what made backboardd's system-container lookup fail
# (error 98 NOT_CODESIGNED) once WindowServer actually started.
#
# The re-signer reproduces the release's own signature byte for byte when run on the
# unmodified library, so it is the same code path that signed it originally.
set -e

SRC=/root/star26/p19/src
DST=/root/star26/p20/src
mkdir -p "$DST"
cp -f "$SRC"/identity "$SRC"/loader.efi "$SRC"/memsize "$SRC"/rdimage "$DST"/
cp -f /root/star26/p20/root.apfs "$DST"/ramdisk

printf 'debug=0x10e rootdev=md0 root_apfs=ufs_darwin launchd_unsecure_cache=1 cpus=4 bootcpu=7 small_cores_after=0 ufs=2 ufs_native=1 ufs_write=1 loader_return_after=600 adreno8=2 adreno8_only=2 rwa_software=1' > "$DST/cmdline"

sed -e 's#/root/star26/p19#/root/star26/p20#g' \
    -e 's#p19-payload#p20-payload#g' \
    -e 's#p19-boot#p20-boot#g' \
    /root/star26/p19/p19-pack.py > /root/star26/p20/p20-pack.py
chmod +x /root/star26/p20/p20-pack.py
cd /root/star26/p20
python3 p20-pack.py
ls -la /root/star26/p20/p20-boot.img
sha256sum /root/star26/p20/p20-boot.img
