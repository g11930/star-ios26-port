#!/bin/bash
set -e
export THEOS=${THEOS:-$HOME/theos}
BASE=/root/star26/s111
STG=$BASE/work/rootbuild/root
U=/root/star26/hackios-xnu-userland

echo "===== 1) 缓存用 68 job 核心集重建 ====="
cd $U/userland
cp -f $STG/xpc/launchd.plist /tmp/launchd-base4.plist
./mkcache.py /tmp/launchd-base4.plist /tmp/jobs-keep /tmp/launchd-new4.plist
cp -f /tmp/launchd-new4.plist $STG/xpc/launchd.plist
python3 - <<'PY'
import plistlib
c = plistlib.load(open('/root/star26/s111/work/rootbuild/root/xpc/launchd.plist','rb'))
print("jobs in cache:", len(c['LaunchDaemons']))
PY

echo "===== 2) ramdisk ====="
python3 $U/tools/apfs/mkapfs.py -z --plain fw -o $BASE/root15.apfs "annibale=$STG" 2>&1 | tail -1
cp -f $BASE/root15.apfs $BASE/parts/ramdisk

echo "===== 3) payload + reseal ====="
python3 /root/star26/hackios-xnu-kernel/xnuloader/mkpayload.py -o $BASE/s127-payload.bin loader.efi=$BASE/parts/loader.efi kernel=$BASE/parts/kernel ramdisk=$BASE/parts/ramdisk rdimage=$BASE/parts/rdimage --cmdline "$(cat $BASE/parts/cmdline)" --memsize "$(cat $BASE/parts/memsize)" --identity "$(cat $BASE/parts/identity)" 2>&1 | tail -1
python3 /root/star26/hackios-xnu-kernel/tools/reseal-loader-img.py -o $BASE/s127-boot.img /root/star26/p2/p2-boot.img $BASE/s127-payload.bin 2>&1 | tail -1
cp -f $BASE/s127-boot.img /mnt/c/ios26/s127-boot.img
sha256sum /mnt/c/ios26/s127-boot.img
echo "===== DONE ====="
</bash>
