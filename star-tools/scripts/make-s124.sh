#!/bash
set -e
export THEOS=${THEOS:-$HOME/theos}
BASE=/root/star26/s111
STG=$BASE/work/rootbuild/root
U=/root/star26/hackios-xnu-userland
LDID=$THEOS/toolchain/linux/iphone/bin/ldid
IOS=/root/star26/ios26

echo "===== 0) 前置检查 ====="
ls -l $STG/xpc/launchd.plist | head -1
echo "--- 缓存里现有的 backboardd 条目:"
python3 - <<'PY'
import plistlib
c = plistlib.load(open('/root/star26/s111/work/rootbuild/root/xpc/launchd.plist','rb'))
k = '/System/Library/LaunchDaemons/com.apple.backboardd.plist'
d = c['LaunchDaemons'][k]
print('old cache ProgramArguments:', d.get('ProgramArguments'))
PY

echo "===== 1) 重新生成 launchd 缓存（以现有缓存为基座）====="
cd $U/userland
cp -f $STG/xpc/launchd.plist /tmp/launchd-base.plist
./mkcache.py /tmp/launchd-base.plist $STG/LaunchDaemons /tmp/launchd-new.plist
cp -f /tmp/launchd-new.plist $STG/xpc/launchd.plist

echo "===== 2) 校验新缓存 ====="
python3 - <<'PY'
import plistlib
c = plistlib.load(open('/root/star26/s111/work/rootbuild/root/xpc/launchd.plist','rb'))
for name in ('com.apple.backboardd.plist', 'com.apple.triald.plist'):
    d = c['LaunchDaemons']['/System/Library/LaunchDaemons/' + name]
    print(name, '->', d.get('ProgramArguments'), 'RunAtLoad=%r' % d.get('RunAtLoad'))
PY

echo "===== 3) 库 = s114 透传版 ====="
cp -f /root/libannibale-s114.dylib $STG/lib/libannibale.dylib
"$LDID" -S $STG/lib/libannibale.dylib && echo libsigned

echo "===== 4) 重打 ramdisk ====="
python3 $U/tools/apfs/mkapfs.py -z --plain fw -o $BASE/root12.apfs "annibale=$STG" 2>&1 | tail -1
cp -f $BASE/root12.apfs $BASE/parts/ramdisk

echo "===== 5) payload + reseal ====="
python3 /root/star26/hackios-xnu-kernel/xnuloader/mkpayload.py -o $BASE/s124-payload.bin loader.efi=$BASE/parts/loader.efi kernel=$BASE/parts/kernel ramdisk=$BASE/parts/ramdisk rdimage=$BASE/parts/rdimage --cmdline "$(cat $BASE/parts/cmdline)" --memsize "$(cat $BASE/parts/memsize)" --identity "$(cat $BASE/parts/identity)" 2>&1 | tail -1
python3 /root/star26/hackios-xnu-kernel/tools/reseal-loader-img.py -o $BASE/s124-boot.img /root/star26/p2/p2-boot.img $BASE/s124-payload.bin 2>&1 | tail -1
cp -f $BASE/s124-boot.img /mnt/c/ios26/s124-boot.img
sha256sum /mnt/c/ios26/s124-boot.img
echo "===== DONE ====="
</bash>
