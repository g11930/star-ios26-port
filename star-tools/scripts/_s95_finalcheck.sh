#!/bin/bash
K=/root/star26/star-native/iokit/Kernel/MiniFramebufferUserClient.inc
echo "=== source vs backup md5 ==="
md5sum "$K" "$K.s95-pre-metal.bak" 2>&1
echo "=== guard present (s94 state)? ==="
sed -n '465,468p' "$K"
echo "=== kern_cs patch count (want 4) ==="
grep -c 'star_cs_keep_valid' /root/star26/star-native/bsd/kern/kern_cs.c
