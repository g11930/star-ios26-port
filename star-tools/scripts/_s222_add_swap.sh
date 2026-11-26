#!/bin/bash
set -e
SWAPFILE=/root/swapfile_proof
if swapon --show | grep -q "$SWAPFILE"; then
  echo "swapfile already active"
else
  echo "creating 8G swapfile at $SWAPFILE"
  fallocate -l 8G "$SWAPFILE" || dd if=/dev/zero of="$SWAPFILE" bs=1M count=8192 status=none
  chmod 600 "$SWAPFILE"
  mkswap "$SWAPFILE" >/dev/null
  swapon "$SWAPFILE"
fi
echo "=== swap now ==="
swapon --show
echo "=== total ==="
grep -i SwapTotal /proc/meminfo
