#!/bin/bash
# Focused run: full output of one write, no truncation, plus the state before and after.
set -u
BIN=/tmp/starfs-hostcheck
IMG=/tmp/gpt-test.img

echo "=== before (fdisk) ==="
fdisk -l "$IMG" 2>&1 | grep -E "^/tmp" | head -5

echo
echo "=== stale snapshots before ==="
ls -la /tmp/starfs-gpt-*.bin 2>/dev/null || echo "none"

echo
echo "=== write p_two -> 8M, full output ==="
"$BIN" gpt write 2 --size 8M --name p_two --commit --dev "$IMG"
echo "exit=$?"

echo
echo "=== after (fdisk) ==="
fdisk -l "$IMG" 2>&1 | grep -E "^/tmp" | head -5

echo
echo "=== snapshots after ==="
ls -la /tmp/starfs-gpt-*.bin 2>/dev/null || echo "none"

echo
echo "=== starfs re-read ==="
"$BIN" gpt list --dev "$IMG" 2>&1 | sed -n '6,10p'
