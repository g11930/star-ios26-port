#!/bash
set -e
export THEOS=${THEOS:-$HOME/theos}
BASE=/root/star26/s111
STG=$BASE/work/rootbuild/root
U=/root/star26/hackios-xnu-userland
LDID=$THEOS/toolchain/linux/iphone/bin/ldid

echo "===== 1) 重签 adhoc ====="
ls -l "$LDID"
"$LDID" -S /root/libannibale-s112.dylib && echo signed
ls -l /root/libannibale-s112.dylib
llvm-objdump --macho --private-headers /root/libannibale-s112.dylib 2>/dev/null | grep -A3 LC_CODE_SIGNATURE | head -5

echo "===== 2) 换进 staging 重打 ramdisk ====="
cp -f /root/libannibale-s112.dylib $STG/lib/libannibale.dylib
python3 $U/tools/apfs/mkapfs.py -z --plain fw -o $BASE/root4.apfs "annibale=$STG" 2>&1 | tail -2
cp -f $BASE/root4.apfs $BASE/parts/ramdisk

echo "===== 3) payload + reseal ====="
python3 /root/star26/hackios-xnu-kernel/xnuloader/mkpayload.py -o $BASE/s113-payload.bin loader.efi=$BASE/parts/loader.efi kernel=$BASE/parts/kernel ramdisk=$BASE/parts/ramdisk rdimage=$BASE/parts/rdimage --cmdline "$(cat $BASE/parts/cmdline)" --memsize "$(cat $BASE/parts/memsize)" --identity "$(cat $BASE/parts/identity)" 2>&1 | tail -1
python3 /root/star26/hackios-xnu-kernel/tools/reseal-loader-img.py -o $BASE/s113-boot.img /root/star26/p2/p2-boot.img $BASE/s113-payload.bin 2>&1 | tail -1
cp -f $BASE/s113-boot.img /mnt/c/ios26/s113-boot.img
sha256sum /mnt/c/ios26/s113-boot.img
echo "===== DONE ====="
</bash>
