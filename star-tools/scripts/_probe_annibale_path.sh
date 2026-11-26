#!/bin/bash
set -u
echo "== init.c: every mention of /annibale =="
grep -n "annibale" /root/star26/hackios-xnu-userland/userland/src/boot/init.c | head -40
echo
echo "== in_image definition =="
grep -n -A12 "in_image(" /root/star26/hackios-xnu-userland/userland/src/boot/init.c | head -30
echo
echo "== libannibalemetal.dylib LC_LOAD_DYLIB / rpath =="
llvm-objdump --macho --dylibs-used /root/star26/s42/work/root/lib/libannibalemetal.dylib 2>/dev/null | head -20
echo
llvm-objdump --macho --private-headers /root/star26/s42/work/root/lib/libannibalemetal.dylib 2>/dev/null | grep -A3 -E "LC_RPATH|LC_LOAD_DYLIB" | grep -E "name|path" | head -12
