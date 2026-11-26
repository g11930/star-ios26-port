#!/bin/bash
# Rollback test driven entirely by the generated restore script.  If this ends with
# sgdisk reporting no problems, both the snapshot layout and the restore offsets are right.
set -u
SRC=/mnt/d/桌面/star26-deps/module/starfs/jni/starfs.c
BIN=/tmp/starfs-hostcheck
IMG=/tmp/gpt-rb.img

echo "=== host build ==="
gcc -std=gnu11 -O1 -o "$BIN" "$SRC" -lz 2>&1 | grep -E "error" | head -5
[ -x "$BIN" ] || { echo "build failed"; exit 1; }

echo "=== fresh image ==="
rm -f "$IMG"; truncate -s 256M "$IMG"
sgdisk -Z "$IMG" >/dev/null 2>&1
sgdisk -o "$IMG" >/dev/null 2>&1
sgdisk -n 1:2048:+32768  -c 1:p_one   "$IMG" >/dev/null 2>&1
sgdisk -n 2:34816:+32768 -c 2:p_two   "$IMG" >/dev/null 2>&1
sgdisk -n 3:67584:+32768 -c 3:p_three "$IMG" >/dev/null 2>&1
fdisk -l "$IMG" 2>&1 | grep -E "^/tmp.*img2"

echo
echo "=== write p_two -> 8M (creates a snapshot + restore script) ==="
"$BIN" gpt write 2 --size 8M --name p_two --commit --snapshot-dir /tmp --dev "$IMG" 2>&1 \
  | grep -E "snapshot|primary|rollback|written"
fdisk -l "$IMG" 2>&1 | grep -E "^/tmp.*img2"

RS=$(ls -t /tmp/starfs-gpt-2-*.restore.sh 2>/dev/null | head -1)
echo
echo "restore script: ${RS:-MISSING}"
if [ -z "${RS:-}" ]; then echo "FAIL: no restore script generated"; exit 1; fi

echo
echo "=== run the generated restore script ==="
sh "$RS" "$IMG"
sync

echo
echo "=== layout after rollback (expect 16M, end 67583) ==="
fdisk -l "$IMG" 2>&1 | grep -E "^/tmp.*img2"

echo
echo "=== sgdisk verification (must be clean) ==="
sgdisk -v "$IMG" 2>&1 | tail -5

echo
echo "=== starfs re-read ==="
"$BIN" gpt list --dev "$IMG" 2>&1 | sed -n '6,9p'
echo "=== DONE ==="
