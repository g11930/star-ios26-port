#!/bin/bash
# P0 pre-flight: prove (or disprove) that the s20 kernel really has a working
# log path from bsd/ code into the loader ring.  Read-only.
set -u
R=/root/star26/star-native
O=$R/BUILD/obj/RELEASE_ARM64_BCM2837
K=$O/mach.release.bcm2837
U=$O/mach.release.bcm2837.unstripped
NM=/root/star-build/xnu-deps/host/bin/nm

echo "=== kernel"
ls -l "$K" "$U"

echo "=== symbols in unstripped"
"$NM" -n "$U" 2>&1 | grep -F -e ' _star_log' -e ' _loader_log_line' -e ' _vsnprintf' -e ' _snprintf' -e ' _star_display_milestone' -e ' _star_trace' -e ' _loader_log_len' -e ' _loader_log_putc' -e ' _star_gate' | head -50

echo "=== object files: who defines / imports loader_log_line"
find "$O" -name '*.o' -print0 | xargs -0 "$NM" -A 2>/dev/null | grep -F 'loader_log_line' | head -30

echo "=== object files: who defines / imports vsnprintf (star objects)"
for f in "$O/bsd/dev/star/star_display_handoff.o" "$O/bsd/kern/kern_exec.o" "$O/osfmk/arm64/loader_return.o"; do
  echo "-- $f"
  ls -l "$f" 2>/dev/null
  "$NM" -n "$f" 2>/dev/null | grep -F -e 'vsnprintf' -e 'snprintf' -e 'loader_log_line' -e 'star_log' -e 'star_trace' -e 'IOLog' | head -20
done

echo "=== stripped vs unstripped size"
ls -l "$K" "$U"

echo "=== DONE"
