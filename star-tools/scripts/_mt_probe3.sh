#!/bin/bash
# Read-only: wait until system_server services are actually ready, then probe intents.
export MSYS_NO_PATHCONV=1
A=/mnt/d/桌面/adb-fastboot/adb.exe

echo "=== wait for package service ==="
ready=0
for i in $(seq 1 60); do
  n=$("$A" shell "pm list packages 2>/dev/null | wc -l" 2>/dev/null | tr -d '\r\n ')
  echo "try $i: packages=$n"
  if [ -n "$n" ] && [ "$n" -gt 50 ] 2>/dev/null; then ready=1; break; fi
  sleep 3
done
[ "$ready" != "1" ] && { echo "ABORT: package service never came up"; exit 2; }

echo
echo "=== 1. file-manager packages ==="
"$A" shell "pm list packages 2>/dev/null | grep -i -E 'mt|file|explorer|documents'" 2>&1 | tr -d '\r'

echo
echo "=== 2. resource/folder handlers for /sdcard/Download ==="
"$A" shell "cmd package query-activities -a android.intent.action.VIEW -d file:///sdcard/Download -t resource/folder 2>&1 | grep -E 'packageName|name=|priority' | head -24" 2>&1 | tr -d '\r'

echo
echo "=== 3. generic dir handlers (no mime) ==="
"$A" shell "cmd package query-activities -a android.intent.action.VIEW -d file:///sdcard/Download 2>&1 | grep -E 'packageName' | head -24" 2>&1 | tr -d '\r'

echo
echo "=== 4. root am start with system chooser ==="
"$A" shell "su -c 'am start --user 0 -a android.intent.action.VIEW -d file:///sdcard/Download -t resource/folder 2>&1 | head -8'" 2>&1 | tr -d '\r'

echo
echo "=== 5. same via cmd activity (fallback path) ==="
"$A" shell "su -c 'cmd activity start --user 0 -a android.intent.action.VIEW -d file:///sdcard/Download -t resource/folder 2>&1 | head -8'" 2>&1 | tr -d '\r'

echo
echo "=== 6. starfs log files: /data/local/tmp ==="
"$A" shell "su -c 'ls -la /data/local/tmp/ | grep -i starfs'" 2>&1 | tr -d '\r'
echo "=== /sdcard/Download ==="
"$A" shell "ls -la /sdcard/Download/ | grep -i starfs" 2>&1 | tr -d '\r'

echo "=== DONE ==="
