#!/bash
set -e
export THEOS=${THEOS:-$HOME/theos}
export PATH="/root/star-build/xnu-deps/host/bin:$THEOS/toolchain/linux/iphone/bin:$PATH"
UL=/root/star26/hackios-xnu-userland/userland
BASE=/root/star26/s111
STG=$BASE/work/rootbuild/root
U=/root/star26/hackios-xnu-userland

cd $UL
echo "===== 1) 编译 libannibale.dylib（s112 常量已改）====="
mkdir -p obj
xnu-clang -arch arm64 -isysroot $THEOS/sdks/iPhoneOS16.5.sdk -O1 \
  -Isrc/boot -Isrc/inject -Isrc/gfx -Isrc/services -Isrc/apps -Isrc/tests \
  -I../../hackios-xnu-kernel/tools/userland-driver \
  -dynamiclib -install_name /annibale/lib/libannibale.dylib \
  -framework CoreFoundation -framework IOKit -lobjc \
  -o obj/libannibale.dylib src/inject/inject.c 2>&1 | tail -8
ls -l obj/libannibale.dylib
strings -a obj/libannibale.dylib | grep -c "detectDisplays"

echo "===== 2) 放进 staging、重建 root.apfs ====="
cp -f obj/libannibale.dylib $STG/lib/libannibale.dylib
md5sum obj/libannibale.dylib $STG/lib/libannibale.dylib
python3 $U/tools/apfs/mkapfs.py -z --plain fw -o $BASE/root3.apfs "annibale=$STG" 2>&1 | tail -2
cp -f $BASE/root3.apfs $BASE/parts/ramdisk
ls -l $BASE/parts/ramdisk

echo "===== 3) payload + reseal ====="
python3 /root/star26/hackios-xnu-kernel/xnuloader/mkpayload.py -o $BASE/s112-payload.bin \
  loader.efi=$BASE/parts/loader.efi kernel=$BASE/parts/kernel ramdisk=$BASE/parts/ramdisk rdimage=$BASE/parts/rdimage \
  --cmdline "$(cat $BASE/parts/cmdline)" --memsize "$(cat $BASE/parts/memsize)" --identity "$(cat $BASE/parts/identity)" 2>&1 | tail -1
python3 /root/star26/hackios-xnu-kernel/tools/reseal-loader-img.py -o $BASE/s112-boot.img /root/star26/p2/p2-boot.img $BASE/s112-payload.bin 2>&1 | tail -1
cp -f $BASE/s112-boot.img /mnt/c/ios26/s112-boot.img
sha256sum /mnt/c/ios26/s112-boot.img
echo "===== DONE ====="
</bash>
