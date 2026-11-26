#!/bin/bash
O=/root/star26/p22/work/root/lib/libannibalemetal.dylib   # the shipped arm64e one
N=/root/star26/p23/libannibalemetal.dylib                 # the new arm64e build
OT=/root/theos/toolchain/linux/iphone/bin/otool
for f in "$O" "$N"; do
  echo "== $f"
  "$OT" -hv "$f" 2>&1 | head -6
  echo "-- first 32 bytes --"
  xxd -l 32 "$f"
done
