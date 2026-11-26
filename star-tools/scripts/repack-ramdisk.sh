#!/bin/bash
# repack-ramdisk.sh <tag> -- rebuild <tag>-boot.img with <tag>/root.apfs as the ramdisk part.
# Everything else in <tag>/parts stays as make-boot.py left it (kernel, loader.efi, rdimage,
# cmdline, memsize, identity).  No device is touched.
set -e
TAG=${1:?usage: repack-ramdisk.sh s34}
BASE=/root/star26/$TAG
PARTS=$BASE/parts
K=/root/star26/hackios-xnu-kernel
[ -f "$BASE/root.apfs" ] || { echo "no $BASE/root.apfs" >&2; exit 1; }
cp -f "$BASE/root.apfs" "$PARTS/ramdisk"
CMD=$(tr -d '\0' < "$PARTS/cmdline")
MEM=$(tr -d '\0' < "$PARTS/memsize")
ID=$(tr -d '\0' < "$PARTS/identity")
echo "=== ramdisk -> $PARTS/ramdisk ($(stat -c %s "$PARTS/ramdisk") bytes)"
echo "=== cmdline ($(printf %s "$CMD" | wc -c)) $CMD"
python3 "$K/xnuloader/mkpayload.py" -o "$BASE/$TAG-payload.bin" \
	loader.efi="$PARTS/loader.efi" \
	kernel="$PARTS/kernel" \
	ramdisk="$PARTS/ramdisk" \
	rdimage="$PARTS/rdimage" \
	--cmdline "$CMD" --memsize "$MEM" --identity "$ID" --checkpoint ""
echo "=== reseal"
python3 "$K/tools/reseal-loader-img.py" -o "$BASE/$TAG-boot.img" \
	/root/star26/p2/p2-boot.img "$BASE/$TAG-payload.bin"
cp -f "$BASE/$TAG-boot.img" "/mnt/c/ios26/$TAG-boot.img"
sha256sum "$BASE/$TAG-boot.img"
ls -la "/mnt/c/ios26/$TAG-boot.img"
