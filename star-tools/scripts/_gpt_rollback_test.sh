#!/bin/bash
# Prove the snapshot is a working rollback: change the table, then restore it with dd and
# confirm both an independent tool and starfs see the original layout again.
set -u
BIN=/tmp/starfs-hostcheck
IMG=/tmp/gpt-test.img
SNAP=/tmp/rollback-test.bin

echo "=== layout now ==="
fdisk -l "$IMG" 2>&1 | grep -E "^/tmp.*img2"

echo
echo "=== write p_two -> 8M ==="
"$BIN" gpt write 2 --size 8M --name p_two --commit --snapshot-dir /tmp --dev "$IMG" 2>&1 | grep -E "snapshot|written"

# the newest snapshot holds the state before this write
LATEST=$(ls -t /tmp/starfs-gpt-2-*.bin | head -1)
cp -f "$LATEST" "$SNAP"
echo "using snapshot: $LATEST"

echo
echo "=== layout after write ==="
fdisk -l "$IMG" 2>&1 | grep -E "^/tmp.*img2"

echo
echo "=== roll back with dd from the snapshot ==="
dd if="$SNAP" of="$IMG" bs=1 conv=notrunc status=none
sync
echo "restored $(stat -c %s "$SNAP") bytes"

echo
echo "=== layout after rollback (expect 16M, end 67583) ==="
fdisk -l "$IMG" 2>&1 | grep -E "^/tmp.*img2"
"$BIN" gpt list --dev "$IMG" 2>&1 | sed -n '7p'

echo
echo "=== sgdisk verification after rollback ==="
sgdisk -v "$IMG" 2>&1 | tail -4
echo "=== DONE ==="
