#!/bin/bash
D=/root/star26/star-native/BUILD/obj/RELEASE_ARM64_BCM2837/bsd/RELEASE
OBJ=$(ls /root/star-build/xnu-deps/host/bin/ | grep -i 'objdump' | head -3)
echo "tools: $OBJ"
OD=/root/star-build/xnu-deps/host/bin/llvm-objdump
[ -x "$OD" ] || OD=/root/star-build/xnu-deps/host/bin/objdump
echo "using $OD"
echo "=== star_display_milestone 的反汇编"
"$OD" -d --disassemble-symbols=star_display_milestone "$D/star_display_handoff.o" 2>&1 | head -30
echo "=== 未定义符号全表（找 IOLog 拼写）"
/root/star-build/xnu-deps/host/bin/nm -u "$D/star_display_handoff.o" 2>&1 | head -20
