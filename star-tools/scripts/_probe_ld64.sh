#!/bin/bash
LD=/root/star26/hackios-xnu-kernel/xnu-deps/host/bin/ld64
echo "=== ld64 file ==="
file "$LD"; ls -la "$LD"; readlink -f "$LD"
echo "=== ld64 version/help head ==="
"$LD" -v 2>&1 | head -5
echo "=== ptrauth/subtype flags ==="
"$LD" -help 2>&1 | grep -i -E "ptrauth|subtype|arm64e|abi|auth" | head -30
echo "=== full help (first 60 lines) ==="
"$LD" -help 2>&1 | head -60
