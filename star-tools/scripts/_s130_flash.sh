#!/bin/bash
export MSYS_NO_PATHCONV=1
F=/mnt/d/桌面/adb-fastboot/fastboot.exe
A=/mnt/d/桌面/adb-fastboot/adb.exe
TAG=s130
cd /mnt/c/ios26 || exit 1

grab () {
  local suf=$1
  rm -f /mnt/c/ios26/${TAG}${suf}-live.bin /mnt/c/ios26/${TAG}${suf}-frame.raw
  timeout 25 "$F" -s xnuloader oem log >/dev/null 2>&1
  timeout 45 "$F" -s xnuloader get_staged "C:/ios26/${TAG}${suf}-live.bin" 2>&1 | tr -d '\r' | tail -1
  timeout 30 "$F" -s xnuloader oem screenshot >/dev/null 2>&1
  timeout 45 "$F" -s xnuloader get_staged "C:/ios26/${TAG}${suf}-frame.raw" 2>&1 | tr -d '\r' | tail -1
  echo "[$(date +%T)] ${TAG}${suf}: log=$(stat -c %s /mnt/c/ios26/${TAG}${suf}-live.bin 2>/dev/null || echo 0)"
}

echo "=== [$(date +%T)] preflight ==="
"$A" start-server >/dev/null 2>&1; sleep 1
ad=$("$A" devices 2>/dev/null | tr -d '\r' | grep -c "device$")
p=$(timeout 8 "$F" getvar product 2>&1 | tr -d '\r' | grep -i product: | head -1)
echo "android=$ad product=$p"
case "$p" in
  *xnuloader*) timeout 15 "$F" -s xnuloader reboot >/dev/null 2>&1; sleep 10 ;;
esac
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

echo "=== [$(date +%T)] sleep 80 ==="; sleep 80
grab "a"
echo "=== [$(date +%T)] sleep 105 ==="; sleep 105
grab "b"
echo "=== [$(date +%T)] sleep 90 ==="; sleep 90
grab "c"
echo "=== [$(date +%T)] DONE ==="
</bash>
