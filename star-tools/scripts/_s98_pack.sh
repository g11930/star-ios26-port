#!/bash
cd /root/star26/star-native || exit 1
K=BUILD/obj/RELEASE_ARM64_BCM2837/mach.release.bcm2837
echo "--- markers:"
strings "$K" | grep -E "star_tdump|entryID=0x%llx" | head -5
echo "--- md5:"
md5sum "$K"
echo "--- pack:"
python3 /mnt/d/桌面/star26-deps/scripts/make-boot.py s98 s97 "" star_msgprobe=1 star_tdump=1 2>&1 | tail -8
echo "--- parts diff vs s97:"
for f in /root/star26/s98/parts/*; do
  b=$(basename "$f")
  if [ -f "/root/star26/s97/parts/$b" ]; then
    if cmp -s "$f" "/root/star26/s97/parts/$b"; then echo "SAME  $b"; else echo "DIFF  $b"; fi
  fi
done
