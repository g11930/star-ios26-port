#!/bash
set -e
export THEOS=${THEOS:-$HOME/theos}
export PATH="/root/star-build/xnu-deps/host/bin:$THEOS/toolchain/linux/iphone/bin:$PATH"
BASE=/root/star26/s111
STG=$BASE/work/rootbuild/root
U=/root/star26/hackios-xnu-userland
LDID=$THEOS/toolchain/linux/iphone/bin/ldid
DYN="xnu-clang -arch arm64 -isysroot $THEOS/sdks/iPhoneOS16.5.sdk -O1"

echo "===== 1) 编译 delayexec ====="
cp -f /mnt/d/桌面/star26-deps/scripts/delayexec.c $U/userland/src/tests/delayexec.c
cd $U/userland && $DYN -o obj/delayexec src/tests/delayexec.c
"$LDID" -S obj/delayexec && echo signed
cp -f obj/delayexec $STG/bin/delayexec
chmod 755 $STG/bin/delayexec

echo "===== 2) backboardd 改为 delayexec 150 ====="
python3 /mnt/d/桌面/star26-deps/scripts/_wrap_bbd.py

echo "===== 3) 重打 ramdisk ====="
python3 $U/tools/apfs/mkapfs.py -z --plain fw -o $BASE/root11.apfs "annibale=$STG" 2>&1 | tail -1
cp -f $BASE/root11.apfs $BASE/parts/ramdisk

echo "===== 4) 回读 ====="
python3 - <<'PY'
import sys, plistlib
sys.path.insert(0, "/root/star-build/tools/apfs")
import apfs
v = apfs.Container("/root/star26/s111/parts/ramdisk").volumes()[0]
ino = v.lookup("/LaunchDaemons/com.apple.backboardd.plist"); ino = ino[0] if isinstance(ino, tuple) else ino
d = plistlib.loads(v.inode(ino).contents())
print("in-image ProgramArguments:", d.get("ProgramArguments"))
PY

echo "===== 5) payload + reseal ====="
python3 /root/star26/hackios-xnu-kernel/xnuloader/mkpayload.py -o $BASE/s123-payload.bin loader.efi=$BASE/parts/loader.efi kernel=$BASE/parts/kernel ramdisk=$BASE/parts/ramdisk rdimage=$BASE/parts/rdimage --cmdline "$(cat $BASE/parts/cmdline)" --memsize "$(cat $BASE/parts/memsize)" --identity "$(cat $BASE/parts/identity)" 2>&1 | tail -1
python3 /root/star26/hackios-xnu-kernel/tools/reseal-loader-img.py -o $BASE/s123-boot.img /root/star26/p2/p2-boot.img $BASE/s123-payload.bin 2>&1 | tail -1
cp -f $BASE/s123-boot.img /mnt/c/ios26/s123-boot.img
sha256sum /mnt/c/ios26/s123-boot.img
echo "===== DONE ====="
</bash>
