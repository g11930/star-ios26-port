#!/bin/bash
echo "=== gpt tools ==="
for t in sgdisk gdisk fdisk sfdisk parted python3; do
    p=$(command -v "$t" 2>/dev/null)
    printf "%-9s %s\n" "$t" "${p:-MISSING}"
done
echo "=== versions ==="
command -v sgdisk >/dev/null 2>&1 && sgdisk --version
command -v fdisk  >/dev/null 2>&1 && fdisk --version
