#!/bin/bash
cd /mnt/c/ios26 || exit 1
for n in 170 171 172 173 174 175 176 177 178 179 180 182 185 188 190; do
  f="s${n}-boot.img"
  [ -f "$f" ] || continue
  python3 /mnt/d/桌面/star26-deps/scripts/xnup_info.py "$f" 2>&1 | grep -vE "^    cmdline:"
  echo
done
