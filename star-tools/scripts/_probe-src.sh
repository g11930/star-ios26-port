#!/bin/bash
set -u
D=/root/star26/hackios-xnu-kernel/tools/userland-driver
echo "== dir =="
ls -la $D 2>/dev/null | head -60
echo
echo "== grep 'half lowering' in tree =="
grep -rn "half lowering" /root/star26/hackios-xnu-kernel 2>/dev/null | head -20
echo
echo "== grep MTLVertexFormatHalf / softpipe sources =="
ls -1 $D/*.m 2>/dev/null | head -30
echo
echo "== who builds libannibaleair =="
grep -rn "libannibaleair" /root/star26/hackios-xnu-kernel --include=*.sh --include=*.py --include=*.mk --include=Makefile 2>/dev/null | head -20
