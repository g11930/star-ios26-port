#!/bin/bash
U=/root/star26/hackios-xnu-userland
echo "=== build script for libsbtrace ==="
grep -rln 'libsbtrace' $U --include=*.sh --include=*.py --include=Makefile* 2>/dev/null | head -6
echo
echo "=== where real_ is resolved in sbtrace.c ==="
grep -n 'real_IOServiceMatching' $U/userland/src/inject/sbtrace.c | head -6
echo
echo "=== the constructor ==="
grep -n 'RTLD_NEXT' -B4 -A4 $U/userland/src/inject/sbtrace.c | head -30
</bash>
