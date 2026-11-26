#!/bin/bash
B=/root/star-build/xnu-deps/build/mesa
echo "=== build/mesa ==="
ls "$B"
echo "=== out ==="
ls -la "$B/out" 2>/dev/null | head -20
echo "=== build dirs ==="
ls -d "$B"/build-* 2>/dev/null
echo "=== air target object dir? ==="
find "$B" -maxdepth 5 -name 'libannibaleair*' 2>/dev/null | head -5
echo "=== release air lib ==="
ls -la /root/star26/release/v0.1.3/hackios-k90-v0.1.3/root/lib/libannibaleair.dylib
/root/theos/toolchain/linux/iphone/bin/otool -l /root/star26/release/v0.1.3/hackios-k90-v0.1.3/root/lib/libannibaleair.dylib 2>/dev/null | grep -A5 LC_BUILD_VERSION | head -12
