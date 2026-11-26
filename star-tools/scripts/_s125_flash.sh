#!/bin/bash
# s125: triald 退回原样 + backboardd delayexec 150；两次抓取（T+165 / T+245）
export MSYS_NO_PATHCONV=1
F=/mnt/d/桌面/adb-fastboot/fastboot.exe
A=/mnt/d/桌面/adb-fastboot/adb.exe
TAG=s125
cd /mnt/c/ios26 || exit 1

grab () {  # grab SUFFIX
  local suf=$1
  rm -f /mnt/c/ios26/${TAG}${suf}-live.bin
  timeout 40 "$F" -s xnuloader oem log 2>&1 | tr -d '\r' | tail -1
  for try in 1 2 3; do
    timeout 45 "$F" -s xnuloader get_staged "C:/ios26/${TAG}${suf}-live.bin" 2>&1 | tr -d '\r' | tail -1
    [ -s /mnt/c/ios26/${TAG}${suf}-live.bin ] && { echo "[$(date +%T)] ${TAG}${suf} log $(stat -c %s /mnt/c/ios26/${TAG}${suf}-live.bin) bytes"; return; }
    sleep 2
  done
}

echo "=== [$(date +%T)] preflight ==="
"$A" start-server >/dev/null 2>&1; sleep 1
ad=$("$A" devices 2>/dev/null | tr -d '\r' | grep -c "device$")
echo "android devices = $ad"
p=$(timeout 8 "$F" getvar product 2>&1 | tr -d '\r' | grep -i product: | head -1)
echo "product: $p"
case "$p" in
  *xnuloader*) echo "in loader: rebooting out"; timeout 15 "$F" -s xnuloader reboot >/dev/null 2>&1; sleep 6 ;;
esac
ok=0
p=$(timeout 6 "$F" getvar product 2>&1 | tr -d '\r' | grep -i product: | head -1)
case "$p" in *star*) echo "already ABL fastboot"; ok=1 ;; esac
if [ "$ok" != "1" ]; then
  [ "$ad" -lt 1 ] && { echo "ABORT: no android and no fastboot"; exit 2; }
  echo "rebooting android -> bootloader"
  "$A" reboot bootloader >/dev/null 2>&1
  for i in $(seq 1 40); do
    sleep 2
    p=$(timeout 6 "$F" getvar product 2>&1 | tr -d '\r' | grep -i product: | head -1)
    case "$p" in *star*) echo "ABL: $p (try $i)"; ok=1; break ;; esac
  done
fi
[ "$ok" != "1" ] && { echo "ABORT: no ABL fastboot"; exit 3; }

echo "=== [$(date +%T)] boot ${TAG} ==="
timeout 120 "$F" boot "C:/ios26/${TAG}-boot.img" 2>&1 | tr -d '\r' | tail -3

echo "=== [$(date +%T)] sleep 165 ==="
sleep 165
echo "=== [$(date +%T)] grab #1 ==="
grab ""
echo "=== [$(date +%T)] sleep 80 ==="
sleep 80
echo "=== [$(date +%T)] grab #2 ==="
grab "b"
echo "=== [$(date +%T)] DONE ==="
</bash>
