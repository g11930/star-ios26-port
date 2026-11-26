#!/bin/bash
for L in /mnt/d/ios26/s217-mid-073704.bin /mnt/d/ios26/s216-mid-072141.bin /mnt/d/ios26/now-071613.bin; do
    echo "=== $L ==="
    grep -a "sensors read" "$L" 2>/dev/null | tail -3
done
