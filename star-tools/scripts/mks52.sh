#!/bin/bash
# mks52.sh -- s52: take the Metal experiment out of SpringBoard/backboardd, put a probe in.
#
# What s51 proved, in its own log:
#   * not one "MiniIOMobileFramebuffer: <proc> selector N" line in 480 s -- no process ever
#     opened the framebuffer user client, so the display road was never started by anybody;
#   * libannibale-sbmetal-experiment.dylib's constructor is run_sequence(), which calls
#     MTLCreateSystemDefaultDevice(), and with metal=1 that call never returns (metal_stubdev
#     stopped inside -[IOGPUMetalDevice initWithAcceleratorPort:] and said nothing more);
#   * that library is inserted into SpringBoard and backboardd, and both sat at 55/69 ms of CPU
#     for the whole run, unchanged -- frozen in a dyld constructor, never reaching main().
#
# So this round changes three things, all of them removals plus one probe:
#   1. cmdline metal=1 -> metal=0: the accelerator service keeps being published, but without
#      MetalPluginName, so CoreAnimation takes its software road -- which is the road this port
#      has for a window server.  applog=2 also goes: it only ever produced launchd's own lines.
#   2. inject.conf line 1 no longer names libannibale-sbmetal-experiment.dylib; it names
#      libsbtrace.dylib for the same four programs.
#   3. libsbtrace.dylib writes to kern.annibale.say: construction, images, IOKit lookups and
#      opens, and a 15 s heartbeat with the main thread's run state.  src/sbtrace.c.
# fbtrace=6 (default 3) only widens the kernel's own selector log; it changes no behaviour.
set -e
U=/root/star26/hackios-xnu-userland/userland
LD64=/root/theos/toolchain/linux/iphone/bin/ld
SDK=/root/theos/sdks/iPhoneOS16.5.sdk
LDID=/root/theos/toolchain/linux/iphone/bin/ldid
S=/root/star26/s52/scripts

mkdir -p /root/star26/s52/work "$S"
rm -rf /root/star26/s52/work/root
cp -a /root/star26/s51/work/root /root/star26/s52/work/root

echo "=== 1. build libsbtrace.dylib (arm64e, adhoc)"
cp -f /mnt/d/桌面/star26-deps/src/sbtrace.c "$U/src/inject/sbtrace.c"
cd "$U"
/usr/bin/clang -target arm64e-apple-ios16.5 --ld-path="$LD64" -isysroot "$SDK" \
	-O1 -arch arm64e -Wall -Wextra \
	-Isrc/boot -Isrc/inject -Isrc/apps \
	-framework IOKit -framework CoreFoundation \
	-dynamiclib -install_name /annibale/lib/libsbtrace.dylib \
	-o obj/libsbtrace.dylib src/inject/sbtrace.c
# The one difference from every library this image already carries: clang 18 through this ld
# leaves cpusubtype at 0x2 where the tree's other dylibs say 0x80000002 (CPU_SUBTYPE_LIB64).
# dyld masks that bit away before comparing, so it decides nothing, but a header that differs
# from the known-good libraries is a variable nobody needs while something else is being
# measured -- and the file has to be signed after the edit either way.
python3 - <<'PY'
import struct
p = "/root/star26/hackios-xnu-userland/userland/obj/libsbtrace.dylib"
d = bytearray(open(p, "rb").read())
cputype, cpusub = struct.unpack_from("<II", d, 4)
if cpusub == 0x2:
    struct.pack_into("<I", d, 8, 0x80000002)
    open(p, "wb").write(d)
    print("cpusubtype 0x2 -> 0x80000002")
else:
    print("cpusubtype already %#x" % cpusub)
PY
"$LDID" -S obj/libsbtrace.dylib
file obj/libsbtrace.dylib
ls -l obj/libsbtrace.dylib
cp -f obj/libsbtrace.dylib /root/star26/s52/work/root/lib/libsbtrace.dylib

echo "=== 2. inject.conf: line 1 -> libsbtrace.dylib"
python3 - <<'PY'
p = "/root/star26/s52/work/root/etc/inject.conf"
lines = open(p).read().splitlines()
old = lines[0]
lines[0] = ("/annibale/lib/libsbtrace.dylib SpringBoard backboardd iconservicesagent "
            "MercuryPosterExtension")
open(p, "w").write("\n".join(lines) + "\n")
print("was:", old)
print("now:", lines[0])
print("bytes:", len(open(p).read()))
PY

echo "=== 3. rc.jobs: probes that need metal=1 are gone"
cat > /root/star26/s52/work/root/etc/rc.jobs <<'EOF'
# s52: the Metal probes are out (metal=0), and what is in is the trace library's own lines.
# lsprobe still samples the four windows; it is what says whether the process table moved.
/annibale/bin/lsprobe 60 &
/annibale/bin/lsprobe 150 &
/annibale/bin/lsprobe 300 &
/annibale/bin/lsprobe 480 &
EOF

echo "=== 4. root.apfs"
cd /root/star26/s52/work
python3 /root/star26/hackios-xnu-userland/tools/apfs/mkapfs.py -z --plain fw \
	-o /root/star26/s52/root.apfs annibale=root 2>&1 | tail -1

echo "=== 5. boot image"
cd /root/star26/star-native
python3 /mnt/d/桌面/star26-deps/scripts/make-boot.py s52 s51 "" metal=0 applog=0 fbtrace=6 2>&1 | tail -3
bash /mnt/d/桌面/star26-deps/scripts/repack-ramdisk.sh s52 2>&1 | tail -4
echo "== cmdline =="
tr -d '\0' < /root/star26/s52/parts/cmdline
echo
ls -l /root/star26/s52/s52-boot.img
