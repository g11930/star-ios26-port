#!/bin/bash
# Aggressive early capture: boot s193, every 3s do oem log + get_staged, save first nonempty.
export MSYS_NO_PATHCONV=1
F=/mnt/d/桌面/adb-fastboot/fastboot.exe
A=/mnt/d/桌面/adb-fastboot/adb.exe
cd /mnt/c/ios26 || exit 1

echo "=== [$(date +%T)] to ABL ==="
"$A" reboot bootloader >/dev/null 2>&1
for i in $(seq 1 30); do sleep 2; p=$(timeout 6 "$F" getvar product 2>&1 | tr -d '\r' | grep -i product: | head -1); case "$p" in *star*) echo "ABL ok"; break;; esac; done

echo "=== [$(date +%T)] boot s193 ==="
timeout 120 "$F" boot C:/ios26/s193-boot.img 2>&1 | tr -d '\r' | tail -1

echo "=== [$(date +%T)] aggressive capture ==="
for r in $(seq 1 40); do
  p=$(timeout 4 "$F" -s xnuloader getvar product 2>&1 | tr -d '\r' | grep -i product: | head -1)
  case "$p" in
    *xnuloader*)
      timeout 8 "$F" -s xnuloader oem log >/dev/null 2>&1
      rm -f /mnt/c/ios26/s193-cap-$r.bin
      timeout 12 "$F" -s xnuloader get_staged "C:/ios26/s193-cap-$r.bin" >/dev/null 2>&1
      sz=$(stat -c %s /mnt/c/ios26/s193-cap-$r.bin 2>/dev/null || echo 0)
      echo "  r$r [$(date +%T)] loader alive, staged=$sz"
      if [ "$sz" -gt 10000 ]; then echo "  GOT at r$r"; echo $r > /tmp/s193_cap_round; break; fi
      rm -f /mnt/c/ios26/s193-cap-$r.bin
      ;;
    *) echo "  r$r [$(date +%T)] loader gone"; break ;;
  esac
  sleep 3
done

echo "=== [$(date +%T)] analyze ==="
python3 - <<'PY'
import glob,os,re
fs=sorted(glob.glob('/mnt/c/ios26/s193-cap-*.bin'),key=os.path.getmtime)
if not fs: print('NO CAPTURE'); raise SystemExit
p=fs[-1]
d=open(p,'rb').read().decode('utf-8','replace').replace('\0','')
print('FILE',os.path.basename(p),len(d),'bytes')
for kw in ['GOODIX_INIT_ENTERED','stm:','goodix:','panic','PANIC','kalloc_type_view','data abort','ESR','backtrace','Kernel fault','KERNEL FAULT','fatal','regress']:
    print('  %-24s %d' % (kw,d.count(kw)))
lines=d.split('\n')
print('--- goodix/stm lines ---')
for l in lines:
    if re.search(r'goodix|stm:|GOODIX',l): print('   ',l.strip()[:200])
print('--- last 12 ---')
for l in [x for x in lines if x.strip()][-12:]: print('   ',l.strip()[:180])
PY
