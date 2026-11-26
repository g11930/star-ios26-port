#!/bin/bash
F=/root/star26/star-native/bsd/dev/star/annibale_goodix.c
echo "--- pins ---"
grep -n '#define PIN_' $F | head -12
echo "--- chip selection ---"
grep -n -B6 -A16 'ID gpio96' $F | head -40
echo "--- fts branch detection ---"
grep -n 'TOUCH_FOCALTECH\|touch_chip =' $F | head -12
</>
