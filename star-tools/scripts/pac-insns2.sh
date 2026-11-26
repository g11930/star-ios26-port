#!/bin/bash
F=/root/star26/p23/libannibalemetal.dylib
O=/root/star26/release/v0.1.3/hackios-k90-v0.1.3/root/lib/libannibalemetal.dylib.v013
OT=/root/theos/toolchain/linux/iphone/bin/otool
for f in "$O" "$F"; do
  echo "== $f"
  "$OT" -tv "$f" > /tmp/dis.txt 2>/dev/null || true
  for m in pacibsp autibsp retab retaa braa blraa pacia autia xpaci ptrauth; do
    printf '  %-8s %s\n' "$m" "$(grep -c -w "$m" /tmp/dis.txt)"
  done
done
