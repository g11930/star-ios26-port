#!/bin/bash
set -u
LIB=/root/star26/s42/work/root/lib/libannibaleair.dylib
llvm-objdump --arch=arm64 --disassemble-symbols=_lower_half_for_backend "$LIB" 2>/dev/null > /tmp/lhfb.txt
echo "lines: $(wc -l < /tmp/lhfb.txt)"
echo "== cmp/sub against small ints (switch shape) =="
grep -nE "cmp\s+w[0-9]+, #0x[0-9a-f]+|sub\s+w[0-9]+, w[0-9]+, #0x[0-9a-f]+" /tmp/lhfb.txt | head -30
echo "== calls =="
grep -nE "\bbl\b" /tmp/lhfb.txt | head -30
