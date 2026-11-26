#!/bin/bash
# s95 = s94 parts + new kernel (unconditional Accelerator plugin props + CS guard).
# Single variable vs s94: only the Metal guard removal in the kernel.
set -e
K=/root/star26/hackios-xnu-kernel
BUILT=/root/star26/star-native/BUILD/obj/RELEASE_ARM64_BCM2837/mach.release.bcm2837
BASE=/root/star26/s95
PARTS=$BASE/parts

echo "=== 0) verify patches via symbol table ==="
NM=/root/star-build/xnu-deps/host/bin/nm
U=$BUILT.unstripped.noctf
echo -n "  _star_cs_keep_valid (want 1): "; "$NM" "$U" 2>/dev/null | grep -c '_star_cs_keep_valid'
echo -n "  _star_cs_probe (want 0): "; "$NM" "$U" 2>/dev/null | grep -c '_star_cs_probe' || true
CS=$("$NM" "$U" 2>/dev/null | grep -c '_star_cs_keep_valid')
[ "$CS" -lt 1 ] && { echo "ABORT: CS patch symbol missing"; exit 1; }

echo "=== 1) create s95 from s94 parts ==="
mkdir -p "$PARTS"
cp -f /root/star26/s94/parts/* "$PARTS/"

echo "=== 2) replace kernel ==="
cp -f "$BUILT" "$PARTS/kernel"
stat -c '  kernel %s bytes' "$PARTS/kernel"
md5sum "$PARTS/kernel" /root/star26/s94/parts/kernel

echo "=== 3) cmdline: keep s94 as-is (metal=0 + star_cs_keep_valid=1) ==="
cmp -s "$PARTS/cmdline" /root/star26/s94/parts/cmdline && echo "  cmdline IDENTICAL to s94" || echo "  WARN: cmdline differs"

echo "=== 4) verify other parts identical to s94 ==="
for f in loader.efi ramdisk rdimage memsize identity cmdline; do
  a=$(md5sum "$PARTS/$f" | cut -d' ' -f1)
  b=$(md5sum "/root/star26/s94/parts/$f" | cut -d' ' -f1)
  [ "$a" = "$b" ] && echo "  $f SAME" || echo "  $f DIFF (UNEXPECTED)"
done

echo "=== 5) payload + reseal ==="
CMD=$(tr -d '\0' < "$PARTS/cmdline")
MEM=$(tr -d '\0' < "$PARTS/memsize")
ID=$(tr -d '\0' < "$PARTS/identity")
python3 "$K/xnuloader/mkpayload.py" -o "$BASE/s95-payload.bin" \
  loader.efi="$PARTS/loader.efi" kernel="$PARTS/kernel" \
  ramdisk="$PARTS/ramdisk" rdimage="$PARTS/rdimage" \
  --cmdline "$CMD" --memsize "$MEM" --identity "$ID" --checkpoint ""

python3 "$K/tools/reseal-loader-img.py" -o "$BASE/s95-boot.img" \
  /root/star26/p2/p2-boot.img "$BASE/s95-payload.bin"

echo "=== 6) deliver ==="
cp -f "$BASE/s95-boot.img" /mnt/c/ios26/s95-boot.img
sha256sum "$BASE/s95-boot.img" /mnt/c/ios26/s95-boot.img
ls -la /mnt/c/ios26/s95-boot.img
echo "=== DONE ==="
