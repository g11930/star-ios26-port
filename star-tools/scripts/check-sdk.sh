#!/bin/bash
echo "=== THEOS ==="
ls -d "$HOME"/theos 2>/dev/null || echo "no theos"
echo "=== sdks ==="
ls "$HOME"/theos/sdks 2>/dev/null | head
echo "=== xnu-clang ==="
ls -la /root/star26/hackios-xnu-kernel/xnu-deps/host/bin/xnu-clang 2>/dev/null || echo "no xnu-clang"
echo "=== other sdk trees ==="
ls -d /root/star-build/xnu-deps/sdk* 2>/dev/null
echo "=== Metal.framework in any sdk ==="
find / -maxdepth 8 -name 'Metal.framework' -type d 2>/dev/null | head -5
