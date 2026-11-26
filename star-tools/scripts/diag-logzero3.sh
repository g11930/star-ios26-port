#!/bin/bash
T=/root/star26/star-native
B=$T/BUILD/obj/RELEASE_ARM64_BCM2837
OBJ=$B/bsd/RELEASE
N=/root/star-build/xnu-deps/host/bin/nm

echo "=== full _star_log disassembly ==="
llvm-objdump --macho --disassemble-symbols=_star_log "$OBJ/star_display_handoff.o" 2>&1 | tail -45

echo "=== full _star_trace disassembly ==="
llvm-objdump --macho --disassemble-symbols=_star_trace "$OBJ/kern_exec.o" 2>&1 | tail -40

echo "=== nm -m: where do _snprintf / _vsnprintf live ==="
$N -m "$B/mach.release.bcm2837" 2>/dev/null | grep -E ' _snprintf| _vsnprintf| _consume_printf_args| _doprnt' | head -10

echo "=== disassemble the linked _vsnprintf ==="
llvm-objdump --macho --disassemble-symbols=_vsnprintf "$B/mach.release.bcm2837" 2>&1 | head -35

echo "=== printf.c VSPRINTF region ==="
grep -n 'CONFIG_VSPRINTF' "$T/osfmk/kern/printf.c" | head -10
