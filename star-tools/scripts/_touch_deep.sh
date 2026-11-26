#!/bin/bash
echo "=== [1] all goodix lines with order ==="
python3 - <<'PY'
import re
d=open('/mnt/c/ios26/s192now-log.bin','rb').read().decode('utf-8','replace').replace('\0','')
lines=d.split('\n')
for i,l in enumerate(lines):
    if re.search(r'goodix|annibale-touch|input26:',l,re.I):
        print('L%d: %s' % (i,l.strip()[:200]))
PY
echo
echo "=== [2] goodix source size and probe flow ==="
wc -l /root/star26/star-native/bsd/dev/star/annibale_goodix.c
grep -n "probe\|i2c\|spi\|goodix:" /root/star26/star-native/bsd/dev/star/annibale_goodix.c | head -50
