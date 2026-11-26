#!/bin/bash
# 组装 s94 = s90 基线 + CS_VALID 守卫补丁内核 + cmdline star_cs_keep_valid=1
set -e
K=/root/star26/hackios-xnu-kernel
BUILT=/root/star26/star-native/BUILD/obj/RELEASE_ARM64_BCM2837/mach.release.bcm2837
BASE=/root/star26/s94
PARTS=$BASE/parts

echo "=== 0) verify patch via symbol table (strings is unreliable: CONFIG_NO_PRINTF_STRINGS merges boot-arg strings) ==="
NM=/root/star-build/xnu-deps/host/bin/nm
U=$BUILT.unstripped.noctf
echo -n "star_cs_keep_valid symbol (want 1): "; "$NM" "$U" 2>/dev/null | grep -c '_star_cs_keep_valid'
echo -n "star_cs_probe symbol (want 0): "; "$NM" "$U" 2>/dev/null | grep -c '_star_cs_probe' || true
if [ "$("$NM" "$U" 2>/dev/null | grep -c '_star_cs_keep_valid')" -lt 1 ]; then
  echo "ABORT: CS patch symbol missing from kernel"; exit 1
fi

echo "=== 1) create s94 from s90 parts (clean baseline) ==="
mkdir -p "$PARTS"
cp -f /root/star26/s90/parts/* "$PARTS/"
echo "copied s90 parts -> $PARTS"

echo "=== 2) replace kernel ==="
cp -f "$BUILT" "$PARTS/kernel"
stat -c 'kernel %s bytes' "$PARTS/kernel"
md5sum "$PARTS/kernel" /root/star26/s90/parts/kernel

echo "=== 3) cmdline: s90 baseline + star_cs_keep_valid=1 ==="
CMD=$(tr -d '\0' < "$PARTS/cmdline")
CMD=$(printf '%s' "$CMD" | sed 's/ star_cs_keep_valid=[01]//g; s/ star_cs_probe=[01]//g')
CMD="$CMD star_cs_keep_valid=1"
printf '%s' "$CMD" > "$PARTS/cmdline"
echo "cmdline bytes: $(wc -c < "$PARTS/cmdline")"
cat "$PARTS/cmdline"; echo

echo "=== 4) verify non-kernel parts identical to s90 ==="
for f in loader.efi ramdisk rdimage memsize identity; do
  a=$(md5sum "$PARTS/$f" | cut -d' ' -f1)
  b=$(md5sum "/root/star26/s90/parts/$f" | cut -d' ' -f1)
  [ "$a" = "$b" ] && echo "  $f SAME" || echo "  $f DIFF (UNEXPECTED)"
done

echo "=== 5) payload + reseal ==="
MEM=$(tr -d '\0' < "$PARTS/memsize")
ID=$(tr -d '\0' < "$PARTS/identity")
python3 "$K/xnuloader/mkpayload.py" -o "$BASE/s94-payload.bin" \
  loader.efi="$PARTS/loader.efi" kernel="$PARTS/kernel" \
  ramdisk="$PARTS/ramdisk" rdimage="$PARTS/rdimage" \
  --cmdline "$CMD" --memsize "$MEM" --identity "$ID" --checkpoint ""

python3 "$K/tools/reseal-loader-img.py" -o "$BASE/s94-boot.img" \
  /root/star26/p2/p2-boot.img "$BASE/s94-payload.bin"

echo "=== 6) deliver to C: ==="
cp -f "$BASE/s94-boot.img" /mnt/c/ios26/s94-boot.img
sha256sum "$BASE/s94-boot.img" /mnt/c/ios26/s94-boot.img
ls -la /mnt/c/ios26/s94-boot.img
echo "=== DONE ==="
