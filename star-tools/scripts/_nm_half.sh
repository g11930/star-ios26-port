#!/bin/bash
set -u
LIB=/root/star26/s42/work/root/lib/libannibaleair.dylib
echo "== local syms matching half =="
llvm-nm -a "$LIB" 2>/dev/null | grep -iE "half" | head -30
echo "== any sym containing check =="
llvm-nm -a "$LIB" 2>/dev/null | grep -iE "check_half|lower_half_for" | head -10
