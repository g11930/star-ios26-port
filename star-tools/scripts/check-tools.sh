#!/bin/bash
echo "=== theos bin ==="
ls /root/theos/toolchain/linux/iphone/bin | head -40
echo "=== llvm tools ==="
ls /usr/lib/llvm-*/bin/llvm-objdump /usr/lib/llvm-*/bin/llvm-nm 2>/dev/null
which llvm-objdump llvm-nm objdump 2>/dev/null
echo "=== xnu-deps host bin ==="
ls /root/star-build/xnu-deps/host/bin | head -40
