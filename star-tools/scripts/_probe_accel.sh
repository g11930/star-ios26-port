#!/bin/bash
F=/root/star26/star-native/iokit/Kernel/MiniFramebufferUserClient.inc
echo "== lines =="
wc -l "$F"
echo "== 430-520 =="
sed -n '430,520p' "$F"
echo "== uses of gAcceleratorTakesProperties =="
grep -n "gAcceleratorTakesProperties" "$F"
