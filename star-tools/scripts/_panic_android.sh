#!/bin/bash
A=/mnt/d/桌面/adb-fastboot/adb.exe
echo "=== android dmesg panic/touch ==="
"$A" shell "dmesg 2>/dev/null | grep -iE 'panic|kalloc|goodix|stm|abort|fault' | tail -40" 2>&1 | tr -d '\r' | tail -40
echo
echo "=== logcat ==="
"$A" logcat -d -t 200 2>/dev/null | grep -iE "panic|kernel|goodix|stm|bootloader" | tail -20
echo
echo "=== logdump partition via dd (base64) ==="
"$A" shell "su -c 'dd if=/dev/block/by-name/logdump bs=4096 count=256 2>/dev/null | base64'" 2>/dev/null | tr -d '\r\n ' | base64 -d > /mnt/c/ios26/s193-logdump.bin 2>/dev/null
ls -la /mnt/c/ios26/s193-logdump.bin 2>/dev/null
python3 - <<'PY'
import os
p='/mnt/c/ios26/s193-logdump.bin'
if not os.path.exists(p): print('no logdump'); raise SystemExit
d=open(p,'rb').read().decode('utf-8','replace').replace('\0','')
print('logdump bytes',len(d))
for kw in ['panic','Panic','stm:','goodix','GOODIX_INIT_ENTERED','kalloc_type_view','data abort','ESR']:
    print('  %-22s %d' % (kw,d.count(kw)))
import re
for m in re.finditer(r'panic|data abort|KERNEL FAULT',d):
    print('CTX:', d[max(0,m.start()-200):m.start()+400].replace('\n',' | ')[:600]); break
PY
