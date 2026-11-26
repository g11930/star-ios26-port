#!/bin/bash
set -u
ROOT=/root/star26/s41/work/root
LIB=$ROOT/lib/libannibale.dylib
echo "== annibale dirs in root =="
ls -1d $ROOT/annibale* 2>/dev/null
ls -1 $ROOT/annibale 2>/dev/null | head
echo "== symlinks mentioning annibale =="
find $ROOT -maxdepth 3 -name 'annibale*' 2>/dev/null | head -20
echo
echo "== symbols =="
llvm-nm -a "$LIB" 2>/dev/null | grep -Ei 'annibale_init|say|bootarg' | head -20
echo
echo "== disasm _annibale_init =="
llvm-objdump --arch=arm64 --disassemble-symbols=_annibale_init "$LIB" 2>/dev/null | head -220
