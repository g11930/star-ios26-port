#!/bin/bash
K=/root/star26/star-native
echo "=== annibale_input sources ==="
ls -l $K/bsd/dev/star/annibale_input* $K/bsd/sys/annibale_input.h 2>/dev/null
echo "=== who writes samples ==="
grep -rn 'ANNIBALE_TOUCH_DEVICE\|annibale_touch_push\|annibale_input_push' $K/bsd $K/iokit 2>/dev/null | head -12
echo "=== touchscreen drivers ==="
ls $K/bsd/dev/star/ 2>/dev/null | head -30
grep -rln 'gt9886\|GT9886\|goodix' $K/bsd/dev/star 2>/dev/null | head
</