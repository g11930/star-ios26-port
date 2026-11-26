#!/bash
set -e
REL=/root/star26/release/v0.1.3/hackios-k90-v0.1.3/root
BASE=/root/star26/s111
PREV=/root/star26/s110
PARTS=$BASE/parts
MK=/root/star26/hackios-xnu-kernel/xnuloader/mkpayload.py
RESEAL=/root/star26/hackios-xnu-kernel/tools/reseal-loader-img.py
REF=/root/star26/p2/p2-boot.img

echo "===== 1) inject.conf 加一行（幂等）====="
cp -f $REL/etc/inject.conf $REL/etc/inject.conf.s111-pre
if ! grep -q "libannibale.dylib" $REL/etc/inject.conf; then
  printf '/annibale/lib/libannibale.dylib backboardd\n' >> $REL/etc/inject.conf
fi
cat $REL/etc/inject.conf

echo "===== 2) 检查 fw / ipsw ====="
ls -d /root/star26/p2/fw /root/star26/ipsw >/dev/null && echo ok

echo "===== 3) 重建 root.apfs ====="
mkdir -p $BASE
python3 /mnt/d/桌面/star26-deps/scripts/build-star26-root.py \
  --fw /root/star26/p2/fw --ipsw /root/star26/ipsw \
  --work $BASE/work/rootbuild --output $BASE/root.apfs 2>&1 | tail -15

echo "===== 4) 组装 parts ====="
mkdir -p $PARTS
for n in loader.efi rdimage memsize identity; do
  cp -f $PREV/parts/$n $PARTS/$n
done
cp -f $PREV/parts/kernel $PARTS/kernel
cp -f $PREV/parts/cmdline $PARTS/cmdline
cp -f $BASE/root.apfs $PARTS/ramdisk
ls -l $PARTS

echo "===== 5) mkpayload ====="
rd() { head -c 4096 "$PARTS/$1" | tr -d '\0' ; }
python3 $MK -o $BASE/s111-payload.bin \
  loader.efi=$PARTS/loader.efi kernel=$PARTS/kernel ramdisk=$PARTS/ramdisk rdimage=$PARTS/rdimage \
  --cmdline "$(cat $PARTS/cmdline)" --memsize "$(cat $PARTS/memsize)" --identity "$(cat $PARTS/identity)" 2>&1 | tail -5

echo "===== 6) reseal ====="
python3 $RESEAL -o $BASE/s111-boot.img $REF $BASE/s111-payload.bin 2>&1 | tail -3
cp -f $BASE/s111-boot.img /mnt/c/ios26/s111-boot.img
ls -l $BASE/s111-boot.img /mnt/c/ios26/s111-boot.img
sha256sum /mnt/c/ios26/s111-boot.img
echo "===== DONE ====="
</bash>
