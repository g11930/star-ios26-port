#!/bin/bash
echo "=== [1] touch evidence in s192 log ==="
python3 - <<'PY'
import re
d=open('/mnt/c/ios26/s192now-log.bin','rb').read().decode('utf-8','replace').replace('\0','')
for pat in [r'input26.*', r'touch.*', r'fts.*', r'goodix.*', r'STM.*', r'i2c.*fts.*', r'spi.*fts.*']:
    hits=[l.strip() for l in d.split('\n') if re.search(pat,l,re.I)]
    print('[%s] %d' % (pat,len(hits)))
    for h in hits[:5]: print('   ',h[:190])
PY
echo
echo "=== [2] touch driver sources in current kernel tree ==="
find /root/star26/star-native -type f \( -iname "*touch*" -o -iname "*fts*" -o -iname "*goodix*" -o -iname "*input26*" \) 2>/dev/null | head -30
echo
echo "=== [3] touch symbols/config in kernel tree ==="
grep -rln "fts_k2\|FTS_K2\|STM.*FTS\|st_fts\|spi@a8c000\|touchscreen=1\|INPUT26" /root/star26/star-native --include=*.c --include=*.h 2>/dev/null | head -20
