#!/bin/bash
K=/root/star26/star-native/iokit/Kernel/MiniFramebufferUserClient.inc
echo "=== current Metal setProperty (should be s90 guard state) ==="
grep -n -B4 -A4 'setProperty(kAcceleratorPluginNameKey' "$K"
echo "=== s91 backup exists + its code ==="
ls -la "$K.s91.bak" 2>&1
grep -n -B4 -A4 'setProperty(kAcceleratorPluginNameKey' "$K.s91.bak" 2>&1
echo "=== diff current vs s91.bak (what changes) ==="
diff -u "$K" "$K.s91.bak" 2>&1 | head -60
echo "=== kern_cs patch in source (want 4) ==="
grep -c 'star_cs_keep_valid' /root/star26/star-native/bsd/kern/kern_cs.c
echo "=== mach_loader s92 probe absent (want 0) ==="
grep -c 'star_cs_probe\|CS_INITPAGE' /root/star26/star-native/bsd/kern/mach_loader.c
