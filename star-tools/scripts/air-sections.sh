#!/bin/bash
set -e
L=/root/star26/release/v0.1.3/hackios-k90-v0.1.3/root/lib/libannibaleair.dylib
OUT=/root/star26/p24
mkdir -p "$OUT"

echo "=== __text section header ==="
/usr/bin/llvm-objdump --macho --section-headers "$L" 2>/dev/null | sed -n '1,14p'
echo "=== code signature range ==="
/root/theos/toolchain/linux/iphone/bin/otool -l "$L" 2>/dev/null | grep -A6 LC_CODE_SIGNATURE | head -10
