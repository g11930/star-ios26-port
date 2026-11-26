#!/bash
set -e
export THEOS=${THEOS:-$HOME/theos}
BASE=/root/star26/s111
STG=$BASE/work/rootbuild/root
U=/root/star26/hackios-xnu-userland
LDID=$THEOS/toolchain/linux/iphone/bin/ldid

echo "===== 1) 改两个 plist ====="
python3 /mnt/d/桌面/star26-deps/scripts/_early_triald.py

echo "===== 2) 库 = s114 透传版 ====="
cp -f /root/libannibale-s114.dylib $STG/lib/libannibale.dylib
"$LDID" -S $STG/lib/libannibale.dylib && echo signed
llvm-objdump --macho -d $STG/lib/libannibale.dylib 2>/dev/null | grep "^    5370:"

echo "===== 3) 重打 ramdisk ====="
python3 $U/tools/apfs/mkapfs.py -z --plain fw -o $BASE/root9.apfs "annibale=$STG" 2>&1 | tail -1
cp -f $BASE/root9.apfs $BASE/parts/ramdisk

echo "===== 4) 回读 ====="
python3 - <<'PY'
import sys, plistlib
sys.path.insert(0, "/root/star-build/tools/apfs")
import apfs
v = apfs.Container("/root/star26/s111/parts/ramdisk").volumes()[0]
for path in ("/LaunchDaemons/com.apple.triald.plist", "/LaunchDaemons/com.apple.backboardd.plist"):
    ino = v.lookup(path); ino = ino[0] if isinstance(ino, tuple) else ino
    d = plistlib.loads(v.inode(ino).contents())
    print(path.split("/")[-1], "RunAtLoad=%r KeepAlive=%r StartInterval=%r" % (d.get("RunAtLoad"), d.get("KeepAlive"), d.get("StartInterval")))
PY

echo "===== 5) payload + reseal ====="
python3 /root/star26/hackios-xnu-kernel/xnuloader/mkpayload.py -o $BASE/s121-payload.bin loader.efi=$BASE/parts/loader.efi kernel=$BASE/parts/kernel ramdisk=$BASE/parts/ramdisk rdimage=$BASE/parts/rdimage --cmdline "$(cat $BASE/parts/cmdline)" --memsize "$(cat $BASE/parts/memsize)" --identity "$(cat $BASE/parts/identity)" 2>&1 | tail -1
python3 /root/star26/hackios-xnu-kernel/tools/reseal-loader-img.py -o $BASE/s121-boot.img /root/star26/p2/p2-boot.img $BASE/s121-payload.bin 2>&1 | tail -1
cp -f $BASE/s121-boot.img /mnt/c/ios26/s121-boot.img
sha256sum /mnt/c/ios26/s121-boot.img
echo "===== DONE ====="
</bash>
