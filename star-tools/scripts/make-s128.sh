#!/bin/bash
set -e
export THEOS=${THEOS:-$HOME/theos}
export PATH="/root/star-build/xnu-deps/host/bin:$THEOS/toolchain/linux/iphone/bin:$PATH"
BASE=/root/star26/s111
STG=$BASE/work/rootbuild/root
U=/root/star26/hackios-xnu-userland

echo "===== 1) 编译 sbstall ====="
xnu-clang -arch arm64 -isysroot $THEOS/sdks/iPhoneOS16.5.sdk -O1 \
  -o $STG/bin/sbstall /mnt/d/桌面/star26-deps/scripts/sbstall.c
chmod +x $STG/bin/sbstall
ldid -S $STG/bin/sbstall
ls -l $STG/bin/sbstall

echo "===== 2) rc.jobs 加一行（放最前） ====="
python3 - <<'PY'
p = '/root/star26/s111/work/rootbuild/root/etc/rc.jobs'
s = open(p).read()
line = '/annibale/bin/sbstall 150 10\n'
if 'sbstall' not in s:
    open(p, 'w').write(line + s)
print(open(p).read()[:200])
PY

echo "===== 3) 缓存回到全量 553 job（s126 基线） ====="
cd $U/userland
cp -f $STG/xpc/launchd.plist /tmp/launchd-base5.plist
./mkcache.py /tmp/launchd-base5.plist $STG/LaunchDaemons /tmp/launchd-new5.plist
cp -f /tmp/launchd-new5.plist $STG/xpc/launchd.plist
python3 -c "import plistlib;c=plistlib.load(open('/root/star26/s111/work/rootbuild/root/xpc/launchd.plist','rb'));print('jobs:',len(c['LaunchDaemons']))"

echo "===== 4) ramdisk ====="
python3 $U/tools/apfs/mkapfs.py -z --plain fw -o $BASE/root16.apfs "annibale=$STG" 2>&1 | tail -1
cp -f $BASE/root16.apfs $BASE/parts/ramdisk

echo "===== 5) payload + reseal ====="
python3 /root/star26/hackios-xnu-kernel/xnuloader/mkpayload.py -o $BASE/s128-payload.bin loader.efi=$BASE/parts/loader.efi kernel=$BASE/parts/kernel ramdisk=$BASE/parts/ramdisk rdimage=$BASE/parts/rdimage --cmdline "$(cat $BASE/parts/cmdline)" --memsize "$(cat $BASE/parts/memsize)" --identity "$(cat $BASE/parts/identity)" 2>&1 | tail -1
python3 /root/star26/hackios-xnu-kernel/tools/reseal-loader-img.py -o $BASE/s128-boot.img /root/star26/p2/p2-boot.img $BASE/s128-payload.bin 2>&1 | tail -1
cp -f $BASE/s128-boot.img /mnt/c/ios26/s128-boot.img
sha256sum /mnt/c/ios26/s128-boot.img
echo "===== DONE ====="
</bash>
