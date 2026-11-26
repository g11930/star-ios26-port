#!/bin/bash
# Static proof that the freshly built arm64 kernel reports arm64e to user space.
# CPU_ARCH_ARMv8 = 0xc, CPU_ARCH_ARMv8E = 0xd (osfmk/arm/cpuid.h:80-82).
B=/root/star26/star-native/BUILD/obj/RELEASE_ARM64_BCM2837
echo "=== cpuid.o candidates ==="
find "$B" -name 'cpuid.o' -print
echo "=== look for the 0xd store in do_cpuid ==="
for O in $(find "$B" -name 'cpuid.o' -print); do
	echo "--- $O"
	llvm-objdump -d --macho "$O" 2>/dev/null | grep -A 25 '<_do_cpuid>:' | head -28
done
