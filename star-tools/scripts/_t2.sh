#!/bin/bash
R=/root/g11930-ref/xnu/files/bsd/dev/redwood_goodix.c
echo "=== ref size ==="; wc -l $R
echo "=== ref pin defines ==="
grep -n '#define PIN_\|#define .*GPIO\|focaltech_id\|goodix_id' $R | head -25
echo "=== ref reset/supply ==="
grep -n 'avdd\|AVDD\|reset\|ldoc\|ldo' $R | head -30