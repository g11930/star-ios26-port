#!/bin/bash
# s126: 缓存重建 + job 零改动（对照组）；T+95 / T+200 两次抓取
export MSYS_NO_PATHCONV=1
F=/mnt/d/桌面/adb-fastboot/fastboot.exe
A=/mnt/d/桌面/adb-fastboot/adb.exe
TAG=s126
cd /mnt/c/ios26 || exit 1

grab () {
  local suf=$1
  rm -f /mnt/c/ios26/${TAG}${suf}-live.bin
  timeout 25 "$F" -s xnuloader oem log 2>&1 | tr -d '\r' | tail -1
  timeout 45 "$F" -s xnuloader get_staged "C:/ios26/${TAG}${suf}-live.bin" 2>&1 | tr -d '\r' | tail -1
  if [ -s /mnt/c/ios26/${TAG}${suf}-live.bin ]; then
    echo "[$(date +%T)] ${TAG}${suf} = $(stat -c %s /mnt/c/ios26/${TAG}${suf}-live.bin) bytes"
  else
    echo "[$(date +%T)] ${TAG}${suf} MISSED"
  fi
}

echo "=== [$(date +%T)] preflight ==="
"$A" start-server >/dev/null 2>&1; sleep 1
ad=$("$A" devices 2>/dev/null | tr -d '\r' | grep -c "device$")
p=$(timeout 8 "$F" getvar product 2>&1 | tr -d '\r' | grep -i product: | head -1)
echo "android=$ad product=$p"
case "$p" in *xnuloader*) timeout 15 "$F" -s xnuloader reboot >/dev/null 2>&1; sleep 6 ;; esac
ok=0
p=$(timeout 6 "$F" getvar product 2>&1 | tr -d '\r' | grep -i product: | head -1)
case "$p" in *star*) ok=1 ;; esac
if [ "$ok" != "1" ]; then
  [ "$ad" -lt 1 ] && { echo "ABORT: no android"; exit 2; }
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

echo "=== [$(date +%T)] sleep 45 ==="; sleep 45
echo "=== [$(date +%T)] try probe p1 ==="; grab "p1"
echo "=== [$(date +%T)] sleep 45 ==="; sleep 45
echo "=== [$(date +%T)] grab T+95 ==="; grab "a"
echo "=== [$(date +%T)] sleep 105 ==="; sleep 105
echo "=== [$(date +%T)] grab T+200 ==="; grab "b"
echo "=== [$(date +%T)] DONE ==="
</bash>
