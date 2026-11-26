#!/bin/bash
K=/root/star26/star-native/iokit/Kernel/MiniFramebufferUserClient.inc
echo "=== exact guard block (current s94 state) ==="
sed -n '460,472p' "$K"
echo "=== md5 ==="
md5sum "$K"
echo "=== CS patch still in source? ==="
grep -c 'star_cs_keep_valid' /root/star26/star-native/bsd/kern/kern_cs.c
echo "=== s92 probe absent? ==="
grep -c 'star_cs_probe' /root/star26/star-native/bsd/kern/mach_loader.c
