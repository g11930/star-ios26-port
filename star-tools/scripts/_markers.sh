#!/bin/bash
KB=/root/star26/kbuild/xnu-12377.121.6
KERN=$KB/BUILD/obj/RELEASE_ARM64_BCM2837/mach.release.bcm2837
echo "=== markers in kbuild kernel ==="
for s in 'MetalPluginName' 'AnnibaleWaitsForGPU' 'fbpaint' 'P34: surface' 's100 started' 'star_cs_keep_valid' 'IOAcceleratorES: published'; do
  printf "%-28s %s\n" "$s" "$(strings -n 6 $KERN | grep -c -- "$s")"
done
echo
echo "=== markers in the kernel we have been booting ==="
K2=/root/star26/s111/parts/kernel
for s in 'MetalPluginName' 'AnnibaleWaitsForGPU' 'fbpaint' 'P34: surface' 's100 started' 'star_cs_keep_valid' 'adreno8' 'RBBM'; do
  printf "%-28s %s\n" "$s" "$(strings -n 6 $K2 | grep -c -- "$s")"
done
echo
echo "=== sizes ==="
ls -la $KERN $K2
