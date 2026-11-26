#!/bin/bash
R=/root/star26/star-native
echo "=== all checkpoint call sites in the kernel tree"
grep -rn 'loader_checkpoint(' "$R" --include='*.c' | head -40
echo "=== all checkpoint numbers 1..20 as literals"
grep -rn 'loader_checkpoint(1[0-5])' "$R" --include='*.c' | head -20
echo "=== DONE"
