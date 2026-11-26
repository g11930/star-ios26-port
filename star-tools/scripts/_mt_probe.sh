#!/system/bin/sh
# Read-only probe: MT Manager package/activity, log file locations, am start capability.
A=/mnt/d/桌面/adb-fastboot/adb.exe

echo "=== adb devices ==="
"$A" devices 2>&1 | tr -d '\r'

echo
echo "=== packages matching mt / file manager ==="
"$A" shell "pm list packages 2>/dev/null | grep -i -E 'mt|file|explorer|manager'" 2>&1 | tr -d '\r' | head -20

echo
echo "=== bin.mt.plus present? ==="
"$A" shell "pm path bin.mt.plus 2>&1" 2>&1 | tr -d '\r' | head -4

echo
echo "=== MT main activity + intent filters ==="
"$A" shell "dumpsys package bin.mt.plus 2>/dev/null | grep -E 'Activity|activity|resource/folder|scheme|Action:|Category:|android.intent.action.VIEW' | head -40" 2>&1 | tr -d '\r'

echo
echo "=== MT launcher activities ==="
"$A" shell "cmd package resolve-activity --brief -a android.intent.action.MAIN -c android.intent.category.LAUNCHER bin.mt.plus 2>&1" 2>&1 | tr -d '\r'

echo
echo "=== candidate log dirs ==="
"$A" shell "ls -la /data/local/tmp/ 2>/dev/null | grep -i -E 'starfs|star|log' | head -15" 2>&1 | tr -d '\r'
"$A" shell "ls -la /sdcard/Download/ 2>/dev/null | grep -i -E 'starfs|star|log' | head -15" 2>&1 | tr -d '\r'

echo
echo "=== starfs log-related commands in binary ==="
"$A" shell "su -c 'starfs 2>&1 | grep -i -E \"log|report|snapshot\"'" 2>&1 | tr -d '\r' | head -12

echo
echo "=== can root run am start (dry, no launch) ==="
"$A" shell "su -c 'am start --user 0 -a android.intent.action.VIEW -d file:///sdcard/Download -t resource/folder -n bin.mt.plus/.MainActivity 2>&1 | head -6'" 2>&1 | tr -d '\r'
