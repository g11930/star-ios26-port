#!/bin/bash
L=/root/star26/release/v0.1.3/hackios-k90-v0.1.3/root/lib/libannibaleair.dylib
TOOL=/root/theos/toolchain/linux/iphone/bin
NM=/root/star-build/xnu-deps/host/bin/llvm-nm
OD=/root/star-build/xnu-deps/host/bin/llvm-objdump
ls -la "$L"
echo "=== code signature? ==="
"$TOOL/otool" -l "$L" 2>/dev/null | grep -c LC_CODE_SIGNATURE
echo "=== arch ==="
file "$L"
echo "=== rwa_buffer_create symbol ==="
"$NM" "$L" 2>/dev/null | grep -E " rwa_buffer_create$| _rwa_buffer_create$" | head
echo "=== PIPE_BIND_SHARED value ==="
grep -rn "define PIPE_BIND_SHARED" /root/star-build/xnu-deps/build/mesa/mesa-25.0.7/src/gallium/include/pipe/p_defines.h
grep -rn "define PIPE_BIND_SHADER_BUFFER\|define PIPE_BIND_CONSTANT_BUFFER\|define PIPE_BIND_INDEX_BUFFER" /root/star-build/xnu-deps/build/mesa/mesa-25.0.7/src/gallium/include/pipe/p_defines.h
echo "=== disassembler available? ==="
"$OD" --version 2>&1 | head -3
