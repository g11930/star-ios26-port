#!/bin/bash
cd /root/star26/star-native
echo "--- who prints 'panel swap' ---"
grep -rn 'panel swap' --include=*.c --include=*.cpp --include=*.h . | grep -v BUILD | head -3
echo "--- print helpers in bsd/dev/star ---"
grep -rn 'void\s+\w+\s*(' bsd/dev/star/annibale_adreno.c | grep -i 'log\|print\|tl' | head -6
echo "--- 'annibale: input: sample' emitter ---"
grep -rn 'sample type' --include=*.c . | grep -v BUILD | head -3
</