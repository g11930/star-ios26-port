#!/bin/bash
# Read-only: bring the phone back from xnuloader, then probe file-manager intents.
export MSYS_NO_PATHCONV=1
A=/mnt/d/桌面/adb-fastboot/adb.exe
F=/mnt/d/桌面/adb-fastboot/fastboot.exe

echo "=== state ==="
"$A" start-server >/dev/null 2>&1
p=$(timeout 8 "$F" getvar product 2>&1 | tr -d '\r' | grep -i '^product:' | head -1)
echo "fastboot: ${p:-none}"

case "$p" in
  *xnuloader*)
    echo "=== rebooting out of xnuloader ==="
    timeout 15 "$F" -s xnuloader reboot 2>&1 | tr -d '\r' | tail -2
    ;;
  *star*)
    echo "=== in ABL fastboot, reboot to android ==="
    timeout 15 "$F" reboot 2>&1 | tr -d '\r' | tail -2
    ;;
esac

echo "=== wait for android ==="
ok=0
for i in $(seq 1 60); do
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
echo "=== 1. file-manager packages installed ==="
"$A" shell "pm list packages 2>/dev/null | grep -i -E 'mt|file|explorer|manager|documents'" 2>&1 | tr -d '\r' | head -20

echo
echo "=== 2. who can handle resource/folder on /sdcard/Download ==="
"$A" shell "cmd package query-activities -a android.intent.action.VIEW -d file:///sdcard/Download -t resource/folder 2>&1 | grep -E 'packageName|name=' | head -20" 2>&1 | tr -d '\r'

echo
echo "=== 3. who can handle plain file:// dir (no mime) ==="
"$A" shell "cmd package query-activities -a android.intent.action.VIEW -d file:///sdcard/Download 2>&1 | grep -E 'packageName' | head -20" 2>&1 | tr -d '\r'

echo
echo "=== 4. starfs logs on disk ==="
"$A" shell "ls -la /sdcard/Download/ 2>/dev/null | grep -i -E 'starfs|star' " 2>&1 | tr -d '\r'
"$A" shell "su -c 'ls -la /data/local/tmp/ 2>/dev/null | grep -i -E \"starfs|star\"'" 2>&1 | tr -d '\r'

echo
echo "=== 5. root am start with chooser (VIEW, no component) ==="
"$A" shell "su -c 'am start --user 0 -a android.intent.action.VIEW -d file:///sdcard/Download -t resource/folder 2>&1 | head -8'" 2>&1 | tr -d '\r'

echo
echo "=== 6. selinux context of ksu shell ==="
"$A" shell "su -c 'id; getenforce'" 2>&1 | tr -d '\r'
echo "=== DONE ==="
