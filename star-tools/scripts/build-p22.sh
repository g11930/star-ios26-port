#!/bin/bash
# P22: P21's kernel (the stub AnnibaleGPU service) plus a driver library that can act on its answer.
#
# P21 proved the kernel side: "AnnibaleGPU: stub service registered", the client opened, and the
# kernel answered kAnnibaleSurface with kIOReturnUnsupported -- yet the window server still logged
# "no drawable". The reason was in the shipped library, not the kernel: the release's
# libannibalemetal.dylib predates the client-memory fallback (annibalemetal_texture.inc:727), so it
# treated that answer as a plain refusal. It has been rebuilt from tools/userland-driver with the
# fallback in it, ad-hoc signed, and put into root.apfs.
set -e

SRC=/root/star26/p21/src
DST=/root/star26/p22/src
mkdir -p "$DST"
cp -f "$SRC"/identity "$SRC"/loader.efi "$SRC"/memsize "$SRC"/rdimage "$DST"/
cp -f /root/star26/p22/root.apfs "$DST"/ramdisk

printf 'debug=0x10e rootdev=md0 root_apfs=ufs_darwin launchd_unsecure_cache=1 cpus=4 bootcpu=7 small_cores_after=0 ufs=2 ufs_native=1 ufs_write=1 loader_return_after=600 adreno8=2 adreno8_only=2 rwa_software=1' > "$DST/cmdline"

sed -e 's#/root/star26/p21#/root/star26/p22#g' \
    -e 's#p21-payload#p22-payload#g' \
    -e 's#p21-boot#p22-boot#g' \
    /root/star26/p21/p21-pack.py > /root/star26/p22/p22-pack.py
chmod +x /root/star26/p22/p22-pack.py
cd /root/star26/p22
python3 p22-pack.py
echo "--- cmdline ---"; cat "$DST/cmdline"; echo
ls -la /root/star26/p22/p22-boot.img
sha256sum /root/star26/p22/p22-boot.img
