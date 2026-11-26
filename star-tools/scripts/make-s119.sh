#!/bash
set -e
export THEOS=${THEOS:-$HOME/theos}
BASE=/root/star26/s111
STG=$BASE/work/rootbuild/root
U=/root/star26/hackios-xnu-userland
LDID=$THEOS/toolchain/linux/iphone/bin/ldid

echo "===== 1) 库回退到 s114（passthrough 钩子，无 sleep）====="
cp -f /root/libannibale-s114.dylib /root/libannibale-s119.dylib
"$LDID" -S /root/libannibale-s119.dylib && echo signed
cp -f /root/libannibale-s119.dylib $STG/lib/libannibale.dylib
llvm-objdump --macho -d $STG/lib/libannibale.dylib 2>/dev/null | grep -A2 "^    5370:" | head -3
llvm-objdump --macho -d $STG/lib/libannibale.dylib 2>/dev/null | grep -A2 "^    4044:" | head -3

echo "===== 2) 延迟 backboardd 的 job ====="
python3 /mnt/d/桌面/star26-deps/scripts/_delay_bbd_job.py

echo "===== 3) 重打 ramdisk ====="
python3 $U/tools/apfs/mkapfs.py -z --plain fw -o $BASE/root7.apfs "annibale=$STG" 2>&1 | tail -1
cp -f $BASE/root7.apfs $BASE/parts/ramdisk

echo "===== 4) 回读确认 plist ====="
python3 - <<'PY'
import sys, plistlib
sys.path.insert(0, "/root/star-build/tools/apfs")
import apfs
c = apfs.Container("/root/star26/s111/parts/ramdisk"); v = c.volumes()[0]
ino = v.lookup("/LaunchDaemons/com.apple.backboardd.plist"); ino = ino[0] if isinstance(ino, tuple) else ino
d = plistlib.loads(v.inode(ino).contents())
print("in-image: RunAtLoad=%r StartInterval=%r KeepAlive=%r" % (d.get("RunAtLoad"), d.get("StartInterval"), d.get("KeepAlive")))
PY

echo "===== 5) payload + reseal ====="
python3 /root/star26/hackios-xnu-kernel/xnuloader/mkpayload.py -o $BASE/s119-payload.bin loader.efi=$BASE/parts/loader.efi kernel=$BASE/parts/kernel ramdisk=$BASE/parts/ramdisk rdimage=$BASE/parts/rdimage --cmdline "$(cat $BASE/parts/cmdline)" --memsize "$(cat $BASE/parts/memsize)" --identity "$(cat $BASE/parts/identity)" 2>&1 | tail -1
python3 /root/star26/hackios-xnu-kernel/tools/reseal-loader-img.py -o $BASE/s119-boot.img /root/star26/p2/p2-boot.img $BASE/s119-payload.bin 2>&1 | tail -1
cp -f $BASE/s119-boot.img /mnt/c/ios26/s119-boot.img
sha256sum /mnt/c/ios26/s119-boot.img
echo "===== DONE ====="
</bash>
