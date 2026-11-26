#!/bash
set -e
export THEOS=${THEOS:-$HOME/theos}
BASE=/root/star26/s111
STG=$BASE/work/rootbuild/root
U=/root/star26/hackios-xnu-userland
LDID=$THEOS/toolchain/linux/iphone/bin/ldid

echo "===== 1) 打补丁 ====="
python3 /mnt/d/桌面/star26-deps/scripts/_patch_lib_s118.py
llvm-objdump --macho -d /root/libannibale-s118.dylib 2>/dev/null | grep -A2 "^    4044:" | head -4

echo "===== 2) 重签 ====="
"$LDID" -S /root/libannibale-s118.dylib && echo signed
ls -l /root/libannibale-s118.dylib

echo "===== 3) 重打 ramdisk ====="
cp -f /root/libannibale-s118.dylib $STG/lib/libannibale.dylib
python3 $U/tools/apfs/mkapfs.py -z --plain fw -o $BASE/root6.apfs "annibale=$STG" 2>&1 | tail -1
cp -f $BASE/root6.apfs $BASE/parts/ramdisk

echo "===== 4) payload + reseal ====="
python3 /root/star26/hackios-xnu-kernel/xnuloader/mkpayload.py -o $BASE/s118-payload.bin loader.efi=$BASE/parts/loader.efi kernel=$BASE/parts/kernel ramdisk=$BASE/parts/ramdisk rdimage=$BASE/parts/rdimage --cmdline "$(cat $BASE/parts/cmdline)" --memsize "$(cat $BASE/parts/memsize)" --identity "$(cat $BASE/parts/identity)" 2>&1 | tail -1
python3 /root/star26/hackios-xnu-kernel/tools/reseal-loader-img.py -o $BASE/s118-boot.img /root/star26/p2/p2-boot.img $BASE/s118-payload.bin 2>&1 | tail -1
cp -f $BASE/s118-boot.img /mnt/c/ios26/s118-boot.img
sha256sum /mnt/c/ios26/s118-boot.img
echo "===== DONE ====="
</bash>
