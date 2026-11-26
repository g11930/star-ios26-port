#!/bin/bash
# Reboot s193 and grab the staged buffer EARLY (get_staged directly, no oem log which wipes panic).
export MSYS_NO_PATHCONV=1
F=/mnt/d/桌面/adb-fastboot/fastboot.exe
A=/mnt/d/桌面/adb-fastboot/adb.exe
cd /mnt/c/ios26 || exit 1

echo "=== [$(date +%T)] Android -> ABL ==="
"$A" devices 2>&1 | tr -d '\r' | grep -q device || { echo no-android; exit 2; }
"$A" reboot bootloader >/dev/null 2>&1
for i in $(seq 1 30); do sleep 2; p=$(timeout 6 "$F" getvar product 2>&1 | tr -d '\r' | grep -i product: | head -1); case "$p" in *star*) echo "ABL ready: $p"; break;; esac; done

echo "=== [$(date +%T)] boot s193 ==="
timeout 120 "$F" boot C:/ios26/s193-boot.img 2>&1 | tr -d '\r' | tail -1

echo "=== [$(date +%T)] poll loader + grab staged at intervals ==="
for r in 1 2 3 4 5 6 7 8 9 10 11 12; do
  sleep 8
  p=$(timeout 5 "$F" -s xnuloader getvar product 2>&1 | tr -d '\r' | grep -i product: | head -1)
  case "$p" in
    *xnuloader*)
      echo "--- round $r [$(date +%T)] loader alive, get_staged ---"
      rm -f /mnt/c/ios26/s193-panic-$r.bin
      timeout 20 "$F" -s xnuloader get_staged "C:/ios26/s193-panic-$r.bin" 2>&1 | tr -d '\r' | tail -1
      if [ -f /mnt/c/ios26/s193-panic-$r.bin ]; then
        sz=$(stat -c %s /mnt/c/ios26/s193-panic-$r.bin 2>/dev/null || echo 0)
        echo "    staged $sz bytes"
        if [ "$sz" -gt 1000 ]; then echo "    GOT DATA at round $r"; break; fi
      fi
      ;;
    *) echo "--- round $r [$(date +%T)] loader gone: $p"; break ;;
  esac
done

echo "=== [$(date +%T)] analyze last staged ==="
python3 - <<'PY'
import glob,os,re
fs=sorted(glob.glob('/mnt/c/ios26/s193-panic-*.bin'), key=os.path.getmtime)
if not fs:
    print('NO staged files'); raise SystemExit
for p in fs[-3:]:
    d=open(p,'rb').read().decode('utf-8','replace').replace('\0','')
    print('===',os.path.basename(p),len(d),'bytes ===')
    for kw in ['panic','Panic','PANIC','kalloc_type_view','data abort','ESR','goodix','stm:','GOODIX_INIT_ENTERED','fault','abort','backtrace','Kernel fault','KERNEL FAULT']:
        c=d.count(kw)
        if c: print('  %-22s %d' % (kw,c))
    # show panic context
    for m in re.finditer(r'panic|Panic|PANIC|KERNEL FAULT|data abort',d):
        print('  --- panic ctx ---')
        print('  '+d[max(0,m.start()-300):m.start()+500].replace('\n',' | ')[:700])
        break
PY
echo "=== [$(date +%T)] DONE ==="
