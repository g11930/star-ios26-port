#!/bin/bash
# s175 diagnostic: boot + 3 timed screenshots + kernel log + verdict stats
export MSYS_NO_PATHCONV=1
F=/mnt/d/桌面/adb-fastboot/fastboot.exe
A=/mnt/d/桌面/adb-fastboot/adb.exe
TAG=s175
cd /mnt/c/ios26 || exit 1

get_staged () { # $1 = local windows path
  timeout 45 "$F" -s xnuloader get_staged "$1" 2>&1 | tr -d '\r' | tail -1
}
snap () { # $1 = suffix
  local suf=$1
  rm -f /mnt/c/ios26/${TAG}${suf}-frame.raw
  timeout 30 "$F" -s xnuloader oem screenshot >/dev/null 2>&1
  get_staged "C:/ios26/${TAG}${suf}-frame.raw"
  python3 - "$suf" <<PY
import sys
suf=sys.argv[1]
d=open('/mnt/c/ios26/${TAG}'+suf+'-frame.raw','rb').read()
nz=sum(1 for b in d if b)
print("${TAG}%s: size %d nonzero %d (%.1f%%) first %08x" % (suf,len(d),nz,100.0*nz/len(d) if d else 0,int.from_bytes(d[:4],'little')))
PY
}

echo "=== [$(date +%T)] preflight ==="
"$A" start-server >/dev/null 2>&1; sleep 1
ad=$("$A" devices 2>/dev/null | tr -d '\r' | grep -c "device$")
p=$(timeout 8 "$F" getvar product 2>&1 | tr -d '\r' | grep -i product: | head -1)
echo "android=$ad product=$p"
waitadb () { for i in $(seq 1 30); do ad=$("$A" devices 2>/dev/null | tr -d "\r" | grep -c "device$"); [ "$ad" -ge 1 ] && return 0; sleep 4; done; return 1; }
case "$p" in *xnuloader*) timeout 15 "$F" -s xnuloader reboot >/dev/null 2>&1; waitadb ;; esac
ok=0
p=$(timeout 6 "$F" getvar product 2>&1 | tr -d '\r' | grep -i product: | head -1)
case "$p" in *star*) ok=1 ;; esac
if [ "$ok" != "1" ]; then
  waitadb || { echo "ABORT: no android"; exit 2; }
  "$A" reboot bootloader >/dev/null 2>&1
  for i in $(seq 1 40); do
    sleep 2
    p=$(timeout 6 "$F" getvar product 2>&1 | tr -d '\r' | grep -i product: | head -1)
    case "$p" in *star*) ok=1; break ;; esac
  done
fi
[ "$ok" != "1" ] && { echo "ABORT: no ABL"; exit 3; }

echo "=== [$(date +%T)] boot ${TAG} ==="
timeout 120 "$F" boot "C:/ios26/${TAG}-boot.img" 2>&1 | tr -d '\r' | tail -2

echo "=== [$(date +%T)] sleep 25 ==="; sleep 25
snap "a"
echo "=== [$(date +%T)] sleep 30 ==="; sleep 30
snap "b"
echo "=== [$(date +%T)] sleep 40 -> kernel log ==="; sleep 40
rm -f /mnt/c/ios26/${TAG}-log.bin
timeout 30 "$F" -s xnuloader oem log >/dev/null 2>&1
get_staged "C:/ios26/${TAG}-log.bin"
echo "=== [$(date +%T)] final screenshot ==="
snap "c"

echo "=== [$(date +%T)] LOG STATS ==="
python3 - <<'PY'
import os,re
p='/mnt/c/ios26/s175-log.bin'
if not os.path.exists(p):
    print('NO LOG FILE'); raise SystemExit
d=open(p,'rb').read().decode('utf-8','replace').replace('\0','')
print('log bytes',len(d))
keys=['error=22','cs_flags=26000000','NOT_CODESIGNED','IOAcceleratorES unavailable',
      'registration device=1','default_before=AnnibaleMetalDevice',
      'WindowServer','first_frame','swap','launchd','SpringBoard','backboardd',
      'panic','sbmetal26','sb26','SecTaskLoadEntitlements','continuation violation',
      'MACT','nx_block_count','rc.jobs','mesa','METAL','GPU','gfx','AnnibaleMetal']
for k in keys:
    print('  %-34s %d' % (k, d.count(k)))
# first/last interesting lines
lines=[l for l in d.split('\n') if l.strip()]
print('--- first 12 ---')
for l in lines[:12]: print(' ',l[:200])
print('--- last 25 ---')
for l in lines[-25:]: print(' ',l[:200])
PY
echo "=== [$(date +%T)] DONE ==="
