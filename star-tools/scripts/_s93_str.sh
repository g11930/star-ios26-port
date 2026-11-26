#!/bin/bash
K=/root/star26/star-native/BUILD/obj/RELEASE_ARM64_BCM2837/mach.release.bcm2837
echo "=== built kernel path/size ==="
ls -la "$K"
echo "=== boot-arg string 'star_cs_keep_valid' ==="
strings -a "$K" | grep -F "star_cs_keep_valid" | head
echo "=== IOLog diagnostic 'KEEP CS_VALID' ==="
strings -a "$K" | grep -iF "KEEP CS_VALID" | head
echo "=== IOLog tag 'star_kv' ==="
strings -a "$K" | grep -iF "star_kv" | head
echo "=== control: P28EXIT ==="
strings -a "$K" | grep -F "P28EXIT" | head
echo "=== control: another kern_cs string 'CODE SIGNING' ==="
strings -a "$K" | grep -F "CODE SIGNING" | head -3
