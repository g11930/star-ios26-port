#!/bin/bash
set -u
for f in /root/star26/s42/work/root/lib/libannibaleair.dylib \
         /root/star26/s42/work/root/lib/libannibalemetal.dylib \
         /root/star26/s42/work/root/lib/libannibale.dylib; do
  echo "--- $(basename "$f")"
  llvm-objdump --macho --private-headers "$f" 2>/dev/null | grep -A1 -E "LC_UUID|LC_CODE_SIGNATURE" | grep -E "uuid|cmd LC_UUID|cmdsize|cmd LC_CODE" | head -4
  echo "size=$(stat -c%s "$f")"
done
