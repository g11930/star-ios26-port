#!/bin/bash
set -u
L=/root/star26/s44/work/root/lib/libannibale-sbmetal-experiment.dylib
echo "== dylibs used =="
llvm-objdump --macho --dylibs-used "$L" 2>/dev/null
echo
echo "== rpaths =="
llvm-objdump --macho --private-headers "$L" 2>/dev/null | grep -A2 LC_RPATH | grep "path" | head -5
echo
echo "== exists check for each dependency that is ours =="
llvm-objdump --macho --dylibs-used "$L" 2>/dev/null | grep annibale | sed 's/^[[:space:]]*//' | while read -r dep; do
  p="/root/star26/s44/work/root${dep#/annibale}"
  [ -f "$p" ] && echo "  ok      $dep" || echo "  MISSING $dep   (root${dep#/annibale})"
done
echo
echo "== same for libannibale.dylib =="
llvm-objdump --macho --dylibs-used /root/star26/s44/work/root/lib/libannibale.dylib 2>/dev/null | grep annibale
