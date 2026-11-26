#!/bin/bash
# Build starfs for arm64.  Two passes: a host build catches syntax and warnings in seconds,
# then the cross build produces the module binary.
set -o pipefail
SRC=/mnt/d/桌面/star26-deps/module/starfs/jni/starfs.c
OUT=/mnt/d/桌面/star26-deps/module/starfs/jni/starfs

echo "=== host syntax pass ==="
if command -v gcc >/dev/null 2>&1; then
    gcc -std=gnu11 -O1 -Wall -Wextra -Wno-unused-parameter -Wno-sign-compare \
        -o /tmp/starfs-hostcheck "$SRC" -lz 2>&1 | head -40
    echo "host exit=$?"
else
    echo "no host gcc, skipping"
fi

echo "=== cross build ==="
ls -la /tmp/zlib-1.3.1/libz.a 2>/dev/null || echo "MISSING /tmp/zlib-1.3.1/libz.a"
aarch64-linux-gnu-gcc -std=gnu11 -O2 -Wall -Wno-unused-parameter -Wno-sign-compare \
    -static -o "$OUT" "$SRC" /tmp/zlib-1.3.1/libz.a 2>&1 | head -40
rc=$?
echo "cross exit=$rc"
if [ $rc -eq 0 ]; then
    aarch64-linux-gnu-strip "$OUT" 2>/dev/null
    ls -la "$OUT"
    md5sum "$OUT"
fi
