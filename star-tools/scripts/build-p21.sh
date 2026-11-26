#!/bin/bash
# P21: P20 plus an AnnibaleGPU service with no GPU behind it.
#
# The one thing standing between the window server and a visible screen was that every
# drawable was nil: annibaledrawable asks the AnnibaleGPU service to describe an IOSurface,
# found no such service ("this kernel was booted without gpu=1"), and returned NULL. With the
# service registered and answering kIOReturnUnsupported, that driver takes the surface's
# memory as the process's own and draws through softpipe -- which is already the registered
# Metal device in SpringBoard and backboardd (P19/P20).
#
# The service is registration only: no register is read, no firmware is loaded, no buffer is
# made, and every request is refused. Nothing here touches the GPU.
set -e

SRC=/root/star26/p20/src
DST=/root/star26/p21/src
mkdir -p "$DST"
cp -f "$SRC"/identity "$SRC"/loader.efi "$SRC"/memsize "$SRC"/rdimage "$SRC"/ramdisk "$DST"/

# Byte for byte P20's command line, so the only difference in this boot is the stub service.
printf 'debug=0x10e rootdev=md0 root_apfs=ufs_darwin launchd_unsecure_cache=1 cpus=4 bootcpu=7 small_cores_after=0 ufs=2 ufs_native=1 ufs_write=1 loader_return_after=600 adreno8=2 adreno8_only=2 rwa_software=1' > "$DST/cmdline"

sed -e 's#/root/star26/p20#/root/star26/p21#g' \
    -e 's#p20-payload#p21-payload#g' \
    -e 's#p20-boot#p21-boot#g' \
    /root/star26/p20/p20-pack.py > /root/star26/p21/p21-pack.py
chmod +x /root/star26/p21/p21-pack.py
cd /root/star26/p21
python3 p21-pack.py
echo "--- cmdline ---"; cat "$DST/cmdline"; echo
wc -c < "$DST/cmdline"
ls -la /root/star26/p21/p21-boot.img
sha256sum /root/star26/p21/p21-boot.img
