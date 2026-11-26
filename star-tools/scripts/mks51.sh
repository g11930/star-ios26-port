#!/bin/bash
# mks51.sh -- s51 = s50 + read-only Metal probes in rc.jobs.  Kernel unchanged.
#
# What s50 established: kern.annibale.say works now, and it says
#     say 13 sb26: loaded in wifid uuid=202a674f-...
# -- libannibale-sb26.dylib IS inserted into wifid (same line of etc/inject.conf names
# SpringBoard Preferences lsd wifid) but never into SpringBoard.
#
# The other open question is where MTLCreateSystemDefaultDevice() blocks: metal_dev's very
# first call is that function, so it prints nothing at all and stays alive for the whole
# round.  Since libannibalemetal's own rw_print() writes to the console (rw_console, or
# stdout) and not one of its lines appeared, Metal never got as far as loading the plugin
# bundle -- the stop is at or before step 3 of the five.
#
# metal_stubdev replays MTLAddDevice's sequence by hand and prints each step before it runs,
# so the last line printed names the step that did not come back.  metal_props shows the two
# properties the sgx service carries (it needs metal=1, which is on).
#
# Not used: dlopen_test -- it is in the source tree but was never built into this image.
set -e
mkdir -p /root/star26/s51/work
rm -rf /root/star26/s51/work/root
cp -a /root/star26/s50/work/root /root/star26/s51/work/root

cat > /root/star26/s51/work/root/etc/rc.jobs <<'EOF'
# interactive: no synthetic touches, for a person holding the phone.
#
# s51: where does Metal stop?  metal_stubdev prints each step of the discovery sequence
# before it runs it; metal_props reads back the two properties on the accelerator service.
/annibale/bin/metal_props &
/annibale/bin/metal_stubdev &
/annibale/bin/metal_dev &
/annibale/bin/lsprobe 60 &
/annibale/bin/lsprobe 150 &
/annibale/bin/lsprobe 300 &
/annibale/bin/lsprobe 480 &
EOF

cd /root/star26/s51/work
python3 /root/star26/hackios-xnu-userland/tools/apfs/mkapfs.py -z --plain fw \
	-o /root/star26/s51/root.apfs annibale=root 2>&1 | tail -1
cd /root/star26/star-native
python3 /mnt/d/桌面/star26-deps/scripts/make-boot.py s51 s50 "" 2>&1 | tail -3
bash /mnt/d/桌面/star26-deps/scripts/repack-ramdisk.sh s51 2>&1 | tail -3
echo "== cmdline =="
tr -d '\0' < /root/star26/s51/parts/cmdline
echo
ls -l /root/star26/s51/s51-boot.img
