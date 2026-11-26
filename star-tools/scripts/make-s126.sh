#!/bin/bash
set -e
export THEOS=${THEOS:-$HOME/theos}
BASE=/root/star26/s111
STG=$BASE/work/rootbuild/root
U=/root/star26/hackios-xnu-userland

echo "===== 1) backboardd 退回原 ProgramArguments ====="
python3 /mnt/d/桌面/star26-deps/scripts/_revert_bbd.py

echo "===== 2) 重建缓存（零 job 改动） ====="
cd $U/userland
cp -f $STG/xpc/launchd.plist /tmp/launchd-base3.plist
./mkcache.py /tmp/launchd-base3.plist $STG/LaunchDaemons /tmp/launchd-new3.plist
cp -f /tmp/launchd-new3.plist $STG/xpc/launchd.plist
python3 - <<'PY'
import plistlib
c = plistlib.load(open('/root/star26/s111/work/rootbuild/root/xpc/launchd.plist','rb'))
print("jobs:", len(c['LaunchDaemons']))
print("bbd:", c['LaunchDaemons']['/System/Library/LaunchDaemons/com.apple.backboardd.plist']['ProgramArguments'])
PY

echo "===== 3) ramdisk ====="
python3 $U/tools/apfs/mkapfs.py -z --plain fw -o $BASE/root14.apfs "annibale=$STG" 2>&1 | tail -1
cp -f $BASE/root14.apfs $BASE/parts/ramdisk

echo "===== 4) payload + reseal ====="
python3 /root/star26/hackios-xnu-kernel/xnuloader/mkpayload.py -o $BASE/s126-payload.bin loader.efi=$BASE/parts/loader.efi kernel=$BASE/parts/kernel ramdisk=$BASE/parts/ramdisk rdimage=$BASE/parts/rdimage --cmdline "$(cat $BASE/parts/cmdline)" --memsize "$(cat $BASE/parts/memsize)" --identity "$(cat $BASE/parts/identity)" 2>&1 | tail -1
python3 /root/star26/hackios-xnu-kernel/tools/reseal-loader-img.py -o $BASE/s126-boot.img /root/star26/p2/p2-boot.img $BASE/s126-payload.bin 2>&1 | tail -1
cp -f $BASE/s126-boot.img /mnt/c/ios26/s126-boot.img
sha256sum /mnt/c/ios26/s126-boot.img
echo "===== DONE ====="
</bash>
