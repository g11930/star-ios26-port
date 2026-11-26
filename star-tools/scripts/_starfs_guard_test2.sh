#!/bin/bash
# Bring the phone back to Android from whatever bootloader state it is in, then run the
# guard checks.  Handles all three states seen on this phone: Android, ABL fastboot
# (product: star), and xnuloader.
export MSYS_NO_PATHCONV=1
A=/mnt/d/桌面/adb-fastboot/adb.exe
F=/mnt/d/桌面/adb-fastboot/fastboot.exe

"$A" start-server >/dev/null 2>&1
p=$(timeout 8 "$F" getvar product 2>&1 | tr -d '\r' | grep -i '^product:' | head -1)
echo "fastboot: ${p:-none}"

case "$p" in
  *xnuloader*) echo "leaving xnuloader"; timeout 15 "$F" -s xnuloader reboot >/dev/null 2>&1 ;;
  *star*)      echo "leaving ABL fastboot"; timeout 15 "$F" reboot >/dev/null 2>&1 ;;
  *)           echo "no fastboot device" ;;
esac

echo "=== waiting for android ==="
ok=0
for i in $(seq 1 50); do
  sleep 2
  ad=$("$A" devices 2>/dev/null | tr -d '\r' | grep -c "device$")
  if [ "$ad" -ge 1 ]; then echo "android online after $((i*2))s"; ok=1; break; fi
done
if [ "$ok" != "1" ]; then
  echo "ABORT: android did not come back"
  "$A" devices 2>&1 | tr -d '\r'
  exit 2
fi
echo
echo "=== plan userdata 180G: preview only, warn but not block ==="
"$A" shell "su -c 'starfs gpt plan 34 --size 180G'" 2>&1 | tr -d '\r'

echo
echo "=== write userdata: must be refused (Android system partition) ==="
"$A" shell "su -c 'starfs gpt write 34 --size 180G --name userdata --commit'" 2>&1 | tr -d '\r'

echo
echo "=== plan darwin 16G (unchanged): no spurious container warning ==="
"$A" shell "su -c 'starfs gpt plan 38 --size 16G'" 2>&1 | tr -d '\r'

echo
echo "=== GPT intact afterwards ==="
"$A" shell "su -c 'starfs gpt list --tsv | tail -4'" 2>&1 | tr -d '\r'
echo "=== DONE ==="
