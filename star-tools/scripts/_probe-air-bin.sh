#!/bin/bash
set -u
NEW=/root/star26/hackios-xnu-kernel/xnu-deps/build/mesa/build-star26/src/gallium/drivers/freedreno/libannibaleair.dylib
OLD=/root/star26/s41/work/root/lib/libannibaleair.dylib
R=/root/star26/hackios-xnu-kernel
echo "== file =="
file "$NEW" "$OLD"
echo
echo "== LC_BUILD_VERSION / minos =="
for f in "$NEW" "$OLD"; do
  echo "--- $f"
  llvm-objdump --macho --private-headers "$f" 2>/dev/null | grep -A4 -E "LC_BUILD_VERSION|LC_VERSION_MIN" | head -12
done
echo
echo "== git log for air_lowering =="
git -C $R log --oneline -10 -- xnu-deps/build/mesa/mesa-26.2.5/src/compiler/air/air_metal_lowering.inc 2>/dev/null | head -12
echo "== git status (short) =="
git -C $R status --porcelain 2>/dev/null | head -20
echo
echo "== undefined symbols: new air =="
llvm-nm -u "$NEW" 2>/dev/null | wc -l
llvm-nm -u "$NEW" 2>/dev/null | grep -viE "libSystem|dyld_stub|objc_msgSend$|\$s" | head -25
