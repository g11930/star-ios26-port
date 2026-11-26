#!/bin/bash
set -u
LIB=/root/star26/s42/work/root/lib/libannibale.dylib
ls -l "$LIB"
llvm-objdump --arch=arm64 --disassemble "$LIB" > /tmp/anna.dis 2>/dev/null
echo "lines: $(wc -l < /tmp/anna.dis)"
echo "camtl hits: $(grep -c camtl /tmp/anna.dis)"
grep -n "camtl" /tmp/anna.dis | head -12
