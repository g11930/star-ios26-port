#!/bin/bash
# Verify the GPT write path on a throwaway image, using sgdisk as an independent judge.
# starfs recomputes both CRCs and rewrites both table copies; sgdisk -v then re-verifies the
# result with a completely separate implementation.  Nothing here touches a real device.
set -u
SRC=/mnt/d/桌面/star26-deps/module/starfs/jni/starfs.c
BIN=/tmp/starfs-hostcheck
IMG=/tmp/gpt-test.img

echo "=== host build ==="
gcc -std=gnu11 -O1 -o "$BIN" "$SRC" -lz 2>&1 | grep -E "error" | head -5
[ -x "$BIN" ] || { echo "host build failed"; exit 1; }
echo "built $BIN"

echo
echo "=== make a 256 MiB image with three 16 MiB partitions (512-byte LBAs) ==="
rm -f "$IMG"
truncate -s 256M "$IMG"
sgdisk -Z "$IMG" >/dev/null 2>&1
sgdisk -o "$IMG" >/dev/null 2>&1
sgdisk -n 1:2048:+32768  -c 1:p_one   "$IMG" >/dev/null 2>&1
sgdisk -n 2:34816:+32768 -c 2:p_two   "$IMG" >/dev/null 2>&1
sgdisk -n 3:67584:+32768 -c 3:p_three "$IMG" >/dev/null 2>&1
sgdisk -p "$IMG" 2>&1 | sed -n '3,10p'

echo
echo "=== starfs reads it (auto-detects 512-byte LBAs) ==="
"$BIN" gpt list --dev "$IMG" 2>&1 | head -12

echo
echo "=== plan: grow p1 to 32M -> must hit p2 ==="
"$BIN" gpt plan 1 --size 32M --dev "$IMG" 2>&1 | tail -6

echo
echo "=== plan: shrink p2 to 8M -> allowed ==="
"$BIN" gpt plan 2 --size 8M --dev "$IMG" 2>&1 | tail -5

echo
echo "=== write: shrink p2 to 8M for real ==="
"$BIN" gpt write 2 --size 8M --name p_two --commit --dev "$IMG" 2>&1 | tail -8

echo
echo "=== sgdisk -v: independent verification of both copies ==="
sgdisk -v "$IMG" 2>&1 | tail -12

echo
echo "=== sgdisk -p: new layout ==="
sgdisk -p "$IMG" 2>&1 | sed -n '3,10p'

echo
echo "=== fdisk cross-check ==="
fdisk -l "$IMG" 2>&1 | tail -8

echo
echo "=== write it back to 16M (reversibility) ==="
"$BIN" gpt write 2 --size 16M --name p_two --commit --dev "$IMG" 2>&1 | tail -4
sgdisk -v "$IMG" 2>&1 | tail -6
sgdisk -p "$IMG" 2>&1 | sed -n '3,10p'

echo
echo "=== rollback test: restore the snapshot taken before the first write ==="
ls -la /tmp/starfs-gpt-*.bin 2>/dev/null | tail -3
echo "=== DONE ==="
