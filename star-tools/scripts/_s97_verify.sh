#!/bash
K=/root/star26/star-native/BUILD/obj/RELEASE_ARM64_BCM2837/mach.release.bcm2837
echo "--- markers:"
strings "$K" | grep -E "star_iv97|star_ex97|star_cs_keep_valid"
echo "--- startup fn symbol:"
nm "$K" 2>/dev/null | grep -i "star_cs_keep_valid_init"
echo "--- s97 parts diff vs s96:"
ls /root/star26/s97/parts/ 2>/dev/null
for f in /root/star26/s97/parts/*; do
  b=$(basename "$f")
  if [ -f "/root/star26/s96/parts/$b" ]; then
    if cmp -s "$f" "/root/star26/s96/parts/$b"; then echo "SAME  $b"; else echo "DIFF  $b"; fi
  fi
done
