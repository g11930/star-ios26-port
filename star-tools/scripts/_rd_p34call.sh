#!/bin/bash
F=/root/star26/star-native/iokit/Kernel/MiniIOMobileFramebuffer.cpp
echo "=== p34_sample call sites ==="
grep -n "p34_sample(" "$F"
echo
echo "=== around each call (main path) ==="
for L in $(grep -n "p34_sample(" "$F" | grep -v "^1[0-9][0-9]:" | cut -d: -f1); do
  echo "--- line $L ---"
  sed -n "$((L-12)),$((L+6))p" "$F"
done
