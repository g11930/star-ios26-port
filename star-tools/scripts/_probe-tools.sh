#!/bin/bash
set -u
LIB=/root/star26/s41/work/root/lib/libannibale.dylib
echo "== tools =="
for t in llvm-objdump objdump llvm-nm nm otool; do
  command -v $t >/dev/null 2>&1 && echo "  have $t: $(command -v $t)"
done
ls /root/star26/toolchain/bin 2>/dev/null | head -30
echo "== root/lib listing (annibale*) =="
ls -l /root/star26/s41/work/root/lib/ | grep -i annibale
echo "== find libannibale-gl =="
ls -l /root/star26/s41/work/root/annibale/lib/ 2>/dev/null | head -40
