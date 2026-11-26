#!/bin/bash
# Disassemble the functions that decide whether a bsd/ log line reaches the
# loader ring.  llvm-objdump --macho wants file offsets, VAs are base+offset.
U=/root/star26/star-native/BUILD/obj/RELEASE_ARM64_BCM2837/mach.release.bcm2837.unstripped
OD=/usr/bin/llvm-objdump
BASE=0xfffffff007004000
for spec in \
  "star_log 0x35583c 0x3558d4" \
  "vsnprintf 0x65be34 0x65bf00" \
  "loader_log_line 0x34673c 0x346830"; do
  set -- $spec
  echo "=== $1 (offset $2)"
  "$OD" --macho -d --start-address="$2" --stop-address="$3" "$U" 2>&1 | head -80
done
echo "=== section layout"
"$OD" --macho --section-headers "$U" 2>&1 | head -30
echo "=== DONE"
