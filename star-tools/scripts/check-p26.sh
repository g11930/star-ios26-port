#!/bin/bash
L=/root/star26/p26/libannibaleair.dylib
T=/root/theos/toolchain/linux/iphone/bin
NM=/root/star26/hackios-xnu-kernel/xnu-deps/host/bin/llvm-nm
OD=/root/star26/hackios-xnu-kernel/xnu-deps/host/bin/llvm-objdump
echo "=== size ==="
ls -la "$L"
echo "=== install name ==="
"$T"/otool -D "$L" | sed -n '2,3p'
echo "=== deps ==="
"$T"/otool -L "$L" | sed -n '2,8p'
echo "=== rwa exports ==="
"$NM" -gU "$L" | awk '{print $NF}' | grep -c '^_rwa_'
echo "=== sample exports ==="
"$NM" -gU "$L" | awk '{print $NF}' | grep '^_rwa_' | head -6
echo "=== PAC insns ==="
"$OD" -d "$L" 2>/dev/null | grep -cE '\b(pacibsp|paciasp|retab|autibsp|autiasp)\b'
echo "=== new source text present ==="
strings "$L" | grep -c 'does not support tex op'
strings "$L" | grep -m1 'does not support tex op'
echo "=== shared/PIPE text present ==="
strings "$L" | grep -c 'the GPU driver would not allocate'
echo "=== sdk version (LC_BUILD_VERSION) ==="
"$OD" --macho --private-headers "$L" 2>/dev/null | grep -A6 'LC_BUILD_VERSION' | head -10
