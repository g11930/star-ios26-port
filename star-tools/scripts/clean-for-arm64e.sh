#!/bin/bash
# Rebuild from scratch with ARCH_STRING_FOR_CURRENT_MACHINE_CONFIG=arm64e.
#
# make does not track compiler-flag changes, so a plain re-run would link the
# old arm64 objects again.  The object directory has to go.
set -e
B=/root/star26/star-native/BUILD/obj/RELEASE_ARM64_BCM2837
K=$B/mach.release.bcm2837
cp -f "$K" /root/star26/mach.arm64.bak 2>/dev/null || true
echo "backed up old kernel: $(ls -la /root/star26/mach.arm64.bak 2>/dev/null | awk '{print $5}') bytes"
rm -rf "$B"
echo "cleaned $B"
