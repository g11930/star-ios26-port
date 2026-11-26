#!/bin/bash
O=/root/star26/release/v0.1.3/hackios-k90-v0.1.3/root/lib/libannibalemetal.dylib.v013
N=/root/star26/p23/libannibalemetal.dylib
OT=/root/theos/toolchain/linux/iphone/bin/otool
for f in "$O" "$N"; do
  echo "== $f"
  "$OT" -hv "$f" 2>&1 | sed -n '1,6p'
  echo "-- header bytes 0..11 --"
  xxd -l 12 "$f"
  echo "-- build version --"
  "$OT" -l "$f" 2>/dev/null | grep -A4 -i "build version\|version min" | head -12
done
