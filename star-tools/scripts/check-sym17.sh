#!/bin/bash
N=/root/star-build/xnu-deps/host/bin/nm
D=/root/star26/star-native/BUILD/obj/RELEASE_ARM64_BCM2837/bsd/RELEASE
for f in kern_exec mach_loader star_display_handoff; do
    echo "--- $f.o undefined:"
    "$N" -u "$D/$f.o" 2>&1 | grep -E 'loader_log|snprintf|star_trace|IOLog'
done
echo "--- loader_return.o defined:"
"$N" /root/star26/star-native/BUILD/obj/RELEASE_ARM64_BCM2837/osfmk/RELEASE/loader_return.o 2>/dev/null | grep -E 'loader_log_line|loader_log_putc'
