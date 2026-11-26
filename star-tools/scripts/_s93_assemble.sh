#!/bin/bash
# 组装 s93: 基于 s91 parts, kernel 换成新编译的, cmdline 追加 star_cs_keep_valid=1, 打包
set -e
K=/root/star26/hackios-xnu-kernel
BUILT=/root/star26/star-native/BUILD/obj/RELEASE_ARM64_BCM2837/mach.release.bcm2837
BASE=/root/star26/s93
PARTS=$BASE/parts

echo "=== 0) verify patch strings in built kernel ==="
strings "$BUILT" | grep -c 'star_cs_keep_valid' || true
strings "$BUILT" | grep -c 'star_kv:' || true

echo "=== 1) create s93 from s91 parts ==="
mkdir -p "$BASE"
cp -f /root/star26/s91/parts/* "$PARTS/" 2>/dev/null || { mkdir -p "$PARTS"; cp -f /root/star26/s91/parts/* "$PARTS/"; }
echo "copied s91 parts -> $PARTS"

echo "=== 2) replace kernel ==="
cp -f "$BUILT" "$PARTS/kernel"
ls -la "$PARTS/kernel"
md5sum "$PARTS/kernel" /root/star26/s92/parts/kernel

echo "=== 3) cmdline: s91 baseline + star_cs_keep_valid=1 (strip NUL) ==="
CMD=$(tr -d '\0' < "$PARTS/cmdline")
# remove any pre-existing star_cs_keep_valid token just in case
CMD=$(printf '%s' "$CMD" | sed 's/ star_cs_keep_valid=[01]//g')
CMD="$CMD star_cs_keep_valid=1"
printf '%s' "$CMD" > "$PARTS/cmdline"
echo "cmdline bytes: $(wc -c < "$PARTS/cmdline")"
cat "$PARTS/cmdline"; echo

echo "=== 4) payload + reseal ==="
MEM=$(tr -d '\0' < "$PARTS/memsize")
ID=$(tr -d '\0' < "$PARTS/identity")
python3 "$K/xnuloader/mkpayload.py" -o "$BASE/s93-payload.bin" \
	loader.efi="$PARTS/loader.efi" \
	kernel="$PARTS/kernel" \
	ramdisk="$PARTS/ramdisk" \
	rdimage="$PARTS/rdimage" \
	--cmdline "$CMD" --memsize "$MEM" --identity "$ID" --checkpoint ""

python3 "$K/tools/reseal-loader-img.py" -o "$BASE/s93-boot.img" \
	/root/star26/p2/p2-boot.img "$BASE/s93-payload.bin"

echo "=== 5) deliver to C: ==="
cp -f "$BASE/s93-boot.img" /mnt/c/ios26/s93-boot.img
sha256sum "$BASE/s93-boot.img"
ls -la /mnt/c/ios26/s93-boot.img

echo "=== DONE ==="
