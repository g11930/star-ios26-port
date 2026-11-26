#!/bash
set -e
export THEOS=${THEOS:-$HOME/theos}
BASE=/root/star26/s111
STG=$BASE/work/rootbuild/root
U=/root/star26/hackios-xnu-userland
LDID=$THEOS/toolchain/linux/iphone/bin/ldid

echo "===== 1) triald 改动退回 ====="
python3 /mnt/d/桌面/star26-deps/scripts/_revert_triald.py

echo "===== 2) 重建 launchd 缓存 ====="
cd $U/userland
cp -f $STG/xpc/launchd.plist /tmp/launchd-base2.plist
./mkcache.py /tmp/launchd-base2.plist $STG/LaunchDaemons /tmp/launchd-new2.plist
cp -f /tmp/launchd-new2.plist $STG/xpc/launchd.plist
python3 - <<'PY'
import plistlib
c = plistlib.load(open('/root/star26/s111/work/rootbuild/root/xpc/launchd.plist','rb'))
for n in ('com.apple.backboardd.plist','com.apple.triald.plist'):
    d = c['LaunchDaemons']['/System/Library/LaunchDaemons/'+n]
    print(n, '->', d.get('ProgramArguments'), 'RunAtLoad=%r KeepAlive=%r' % (d.get('RunAtLoad'), d.get('KeepAlive')))
PY

echo "===== 3) 重打 ramdisk ====="
python3 $U/tools/apfs/mkapfs.py -z --plain fw -o $BASE/root13.apfs "annibale=$STG" 2>&1 | tail -1
cp -f $BASE/root13.apfs $BASE/parts/ramdisk

echo "===== 4) payload + reseal ====="
python3 /root/star26/hackios-xnu-kernel/xnuloader/mkpayload.py -o $BASE/s125-payload.bin loader.efi=$BASE/parts/loader.efi kernel=$BASE/parts/kernel ramdisk=$BASE/parts/ramdisk rdimage=$BASE/parts/rdimage --cmdline "$(cat $BASE/parts/cmdline)" --memsize "$(cat $BASE/parts/memsize)" --identity "$(cat $BASE/parts/identity)" 2>&1 | tail -1
python3 /root/star26/hackios-xnu-kernel/tools/reseal-loader-img.py -o $BASE/s125-boot.img /root/star26/p2/p2-boot.img $BASE/s125-payload.bin 2>&1 | tail -1
cp -f $BASE/s125-boot.img /mnt/c/ios26/s125-boot.img
sha256sum /mnt/c/ios26/s125-boot.img
echo "===== DONE ====="
</bash>
