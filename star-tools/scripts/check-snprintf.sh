#!/bin/bash
K=/root/star26/star-native/BUILD/obj/RELEASE_ARM64_BCM2837/mach.release.bcm2837
N=/root/star-build/xnu-deps/host/bin/nm
D=/root/star26/star-native/BUILD/obj/RELEASE_ARM64_BCM2837
echo "=== kernel: is snprintf defined? ==="
"$N" "$K" 2>/dev/null | grep -E ' _snprintf$| _vsnprintf$| _loader_log_line$| _loader_log_putc$| _snprintf_va$'
echo "=== kern_exec.o undefined ==="
"$N" -u "$D/bsd/RELEASE/kern_exec.o" 2>/dev/null | grep -E 'snprintf|loader_log|star_gate'
echo "=== star_display_handoff.o undefined ==="
f=$(find "$D" -name 'star_display_handoff.o' | head -1)
echo "  $f"
"$N" -u "$f" 2>/dev/null | grep -E 'snprintf|loader_log|IOLog'
echo "=== __doprnt present? ==="
"$N" "$K" 2>/dev/null | grep -E ' _?__doprnt' | head
echo "=== vadd / printf family ==="
"$N" "$K" 2>/dev/null | grep -E ' _(v)?snprintf| _printf$| _consdebug' | head
