#!/bin/bash
# mks49.sh -- s49 = s48 + boot-arg metal=1.  One variable.
#
# Why: star-native/iokit/Kernel/MiniFramebufferUserClient.inc:457-470.
#
#   gAcceleratorTakesProperties = PE_parse_boot_argn("metal", &metal, ...) && metal != 0;
#   ...
#   if (gAcceleratorTakesProperties && metal_native != 0) {
#       accelerator->setProperty("MetalPluginName",      "AnnibaleMetal");
#       accelerator->setProperty("MetalPluginClassName", "AnnibaleMetalDevice");
#   }
#   accelerator->registerService();
#
# The comment above that code says it outright: "An accelerator without the properties
# that name its Metal and OpenGL ES drivers is passed over by both, which leaves
# CoreAnimation with its software renderer"; and "with the first missing it returns nil
# before it even reads the second, and that single cbz is where the chain breaks on this
# port today."
#
# The image publishes the sgx IOAccelerator with no plugin properties, so Metal's device
# discovery returns nil in every process.  backboardd therefore never gets a device, never
# starts the window server, and SpringBoard waits for it forever -- which is exactly what
# s43..s48 logs show (backboardd alive, no StartWindowServer, no frames).
#
# metal_native defaults to 1, so metal=1 alone publishes both properties.
#
# Diagnostics in this round (read-only, no behavioural change):
#   - metal_dev : MTLCreateSystemDefaultDevice() in a plain process
#   - starcat   : read /System/Library/Extensions/AnnibaleMetal.bundle/Info.plist, which
#                 proves the symlink the system image needs is really there
set -e
mkdir -p /root/star26/s49/work
rm -rf /root/star26/s49/work/root
cp -a /root/star26/s48/work/root /root/star26/s49/work/root

cat > /root/star26/s49/work/root/etc/rc.jobs <<'EOF'
# interactive: no synthetic touches, for a person holding the phone.
#
# s49: metal=1 (cmdline).  The accelerator service must carry MetalPluginName /
# MetalPluginClassName for Metal to find /System/Library/Extensions/AnnibaleMetal.bundle.
/annibale/bin/annsh &
/annibale/bin/trollstorehelper watch &
/annibale/bin/metal_dev &
/annibale/bin/lsprobe 60 &
/annibale/bin/lsprobe 150 &
/annibale/bin/lsprobe 300 &
/annibale/bin/lsprobe 480 &
/annibale/bin/starcat -t 200 -n 4000 /System/Library/Extensions/AnnibaleMetal.bundle/Info.plist &
/annibale/bin/starcat -t 260 -n 60000 -p backboardd /private/var/mobile/Library/Logs/CrashReporter &
EOF

cd /root/star26/s49/work
python3 /root/star26/hackios-xnu-userland/tools/apfs/mkapfs.py -z --plain fw \
	-o /root/star26/s49/root.apfs annibale=root 2>&1 | tail -1
cd /root/star26/star-native
python3 /mnt/d/桌面/star26-deps/scripts/make-boot.py s49 s48 "" \
	metal=1 loader_return_after=600 2>&1 | tail -3
bash /mnt/d/桌面/star26-deps/scripts/repack-ramdisk.sh s49 2>&1 | tail -3
echo "== cmdline =="
tr -d '\0' < /root/star26/s49/parts/cmdline
echo
ls -l /root/star26/s49/s49-boot.img
sha256sum /root/star26/s49/s49-boot.img
