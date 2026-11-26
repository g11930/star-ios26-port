#!/bin/bash
S=/root/star26/star-native/bsd/dev/star/annibale_goodix.c
echo "=== STAR pin/SE/reg defines ==="
grep -nE "^#define (SE_PHYS|TLMM_PHYS|CMD_DB_PHYS|RSC_PHYS|GCC_PHYS|PIN_MISO|PIN_MOSI|PIN_CLK|PIN_CS|PIN_INT|PIN_RESET|PIN_AVDD|PIN_FOCALTECH_ID|PIN_GOODIX_ID|PIN_FUNCTION_SPI|VOTE_QUP1_SE5|VOTE_QUP1_CORE|GCC_QUP1_M_AHB_CBCR|GCC_QUP1_S_AHB_CBCR|GCC_QUP1_SE5_CBCR)" "$S"
echo
echo "=== STAR id detection ==="
grep -n -A6 "touch_chip_detect" "$S" | head -20
echo
echo "=== STAR power_on / show_state as-found values from last log ==="
python3 - <<'PY'
d=open('/mnt/c/ios26/s192now-log.bin','rb').read().decode('utf-8','replace').replace('\0','')
for l in d.split('\n'):
    if 'goodix: as found' in l or 'goodix: no answer' in l or 'goodix: ID gpio' in l:
        print(l.strip()[:300])
PY
