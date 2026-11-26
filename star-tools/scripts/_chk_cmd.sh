#!/bin/bash
X=/mnt/d/桌面/star26-deps/scripts/xnup_info.py
for img in s196 s197 s192 s175; do
  p=/mnt/c/ios26/$img-boot.img
  [ -f "$p" ] || continue
  echo "=== $img ==="
  python3 "$X" "$p" cmdline 2>/dev/null > /tmp/cl_$img.bin
  tr -d '\0' < /tmp/cl_$img.bin | fold -w 200
  echo
  echo "  bytes: $(tr -d '\0' < /tmp/cl_$img.bin | wc -c)"
done
