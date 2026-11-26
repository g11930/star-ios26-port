#!/bin/bash
M=/root/star26/hackios-xnu-kernel/xnu-deps/build/mesa/mesa-26.2.5
A=$M/src/compiler/air
echo "=== lowering.inc lines ==="
wc -l $A/air_metal_lowering.inc
echo "=== signature / entry ==="
grep -n "^static\|^bool\|^void\|^unsigned\|^int\|lower_half\|refused" $A/air_metal_lowering.inc | head -40
echo
echo "=== distro air dylib size & deps ==="
ls -la /root/star26/release/v0.1.3/hackios-k90-v0.1.3/root/lib/libannibaleair.dylib
/root/theos/toolchain/linux/iphone/bin/otool -L /root/star26/release/v0.1.3/hackios-k90-v0.1.3/root/lib/libannibaleair.dylib 2>/dev/null | head -20
echo
echo "=== air meson.build ==="
cat $A/meson.build
