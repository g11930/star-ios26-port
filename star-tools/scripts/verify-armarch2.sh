#!/bin/bash
# Print raw disassembly of cpuid.o to find the arm_arch store.
B=/root/star26/star-native/BUILD/obj/RELEASE_ARM64_BCM2837
O="$B/osfmk/RELEASE/cpuid.o"
echo "=== file ==="
ls -la "$O"
echo "=== nm (Apple nm) ==="
/root/star-build/xnu-deps/host/bin/nm "$O" 2>&1 | head -25
echo "=== llvm-objdump -d --macho raw head ==="
llvm-objdump -d --macho "$O" 2>&1 | head -40
echo "=== llvm-objdump -d (no flag) raw head ==="
llvm-objdump -d "$O" 2>&1 | head -40
