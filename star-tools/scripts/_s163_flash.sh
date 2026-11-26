#!/bin/bash
# s131: fbpaint=1 判据 —— 早窗口截图（T+20 / T+45）
export MSYS_NO_PATHCONV=1
F=/mnt/d/桌面/adb-fastboot/fastboot.exe
A=/mnt/d/桌面/adb-fastboot/adb.exe
TAG=s163
cd /mnt/c/ios26 || exit 1

snap () {
  local suf=$1
  rm -f /mnt/c/ios26/${TAG}${suf}-frame.raw
  timeout 30 "$F" -s xnuloader oem screenshot >/dev/null 2>&1
  timeout 45 "$F" -s xnuloader get_staged "C:/ios26/${TAG}${suf}-frame.raw" 2>&1 | tr -d '\r' | tail -1
  python3 - <<PY
d = open('/mnt/c/ios26/${TAG}${suf}-frame.raw','rb').read()
nz = sum(1 for b in d if b)
print("${TAG}${suf}: size %d nonzero %d first %08x" % (len(d), nz, int.from_bytes(d[:4],'little')))
PY
}

echo "=== [$(date +%T)] preflight ==="
"$A" start-server >/dev/null 2>&1; sleep 1
ad=$("$A" devices 2>/dev/null | tr -d '\r' | grep -c "device$")
p=$(timeout 8 "$F" getvar product 2>&1 | tr -d '\r' | grep -i product: | head -1)
echo "android=$ad product=$p"
waitadb () { for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30; do ad=$("$A" devices 2>/dev/null | tr -d "\r" | grep -c "device$"); [ "$ad" -ge 1 ] && return 0; sleep 4; done; return 1; }
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

echo "=== [$(date +%T)] sleep 22 ==="; sleep 22
snap "a"
echo "=== [$(date +%T)] sleep 25 ==="; sleep 25
snap "b"
echo "=== [$(date +%T)] sleep 60 ==="; sleep 60
snap "c"
echo "=== [$(date +%T)] DONE ==="
</bash>
