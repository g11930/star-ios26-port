#!/bin/bash
# s96 = s95 + MAC hook CS_VALID patch (boot-arg star_cs_valid=1). Step2.
set -e
K=/root/star26/hackios-xnu-kernel
BUILT=/root/star26/star-native/BUILD/obj/RELEASE_ARM64_BCM2837/mach.release.bcm2837
BASE=/root/star26/s96
PARTS=$BASE/parts

echo "=== 0) verify both patches via symbol table ==="
NM=/root/star-build/xnu-deps/host/bin/nm
U=$BUILT.unstripped.noctf
echo -n "  _star_cs_keep_valid (step1 CS guard, want 1): "; "$NM" "$U" 2>/dev/null | grep -c '_star_cs_keep_valid'
echo -n "  _star_cs_valid (step2 hook, want 1): "; "$NM" "$U" 2>/dev/null | grep -c '_star_cs_valid'
echo -n "  _star_cs_probe (want 0): "; "$NM" "$U" 2>/dev/null | grep -c '_star_cs_probe' || true
A=$("$NM" "$U" 2>/dev/null | grep -c '_star_cs_valid')
[ "$A" -lt 1 ] && { echo "ABORT: step2 symbol missing"; exit 1; }

echo "=== 1) create s96 from s95 parts ==="
mkdir -p "$PARTS"
cp -f /root/star26/s95/parts/* "$PARTS/"

echo "=== 2) replace kernel ==="
cp -f "$BUILT" "$PARTS/kernel"
stat -c '  kernel %s bytes' "$PARTS/kernel"
md5sum "$PARTS/kernel" /root/star26/s95/parts/kernel

echo "=== 3) cmdline: s95 + star_cs_valid=1 ==="
CMD=$(tr -d '\0' < "$PARTS/cmdline")
CMD=$(printf '%s' "$CMD" | sed 's/ star_cs_valid=[01]//g')
CMD="$CMD star_cs_valid=1"
printf '%s' "$CMD" > "$PARTS/cmdline"
echo "  bytes: $(wc -c < "$PARTS/cmdline")"
echo "  $CMD"

echo "=== 4) verify other parts identical to s95 ==="
for f in loader.efi ramdisk rdimage memsize identity; do
  a=$(md5sum "$PARTS/$f" | cut -d' ' -f1)
  b=$(md5sum "/root/star26/s95/parts/$f" | cut -d' ' -f1)
  [ "$a" = "$b" ] && echo "  $f SAME" || echo "  $f DIFF (UNEXPECTED)"
done

echo "=== 5) payload + reseal ==="
MEM=$(tr -d '\0' < "$PARTS/memsize")
ID=$(tr -d '\0' < "$PARTS/identity")
python3 "$K/xnuloader/mkpayload.py" -o "$BASE/s96-payload.bin" \
  loader.efi="$PARTS/loader.efi" kernel="$PARTS/kernel" \
  ramdisk="$PARTS/ramdisk" rdimage="$PARTS/rdimage" \
  --cmdline "$CMD" --memsize "$MEM" --identity "$ID" --checkpoint ""

python3 "$K/tools/reseal-loader-img.py" -o "$BASE/s96-boot.img" \
  /root/star26/p2/p2-boot.img "$BASE/s96-payload.bin"

echo "=== 6) deliver ==="
cp -f "$BASE/s96-boot.img" /mnt/c/ios26/s96-boot.img
sha256sum "$BASE/s96-boot.img" /mnt/c/ios26/s96-boot.img
ls -la /mnt/c/ios26/s96-boot.img
echo "=== DONE ==="
