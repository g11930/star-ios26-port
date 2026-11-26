#!/bin/bash
# Read-only-ish: parse candidate list format, and verify -n launch opens the folder.
export MSYS_NO_PATHCONV=1
A=/mnt/d/桌面/adb-fastboot/adb.exe

echo "=== A. brief format for */* ==="
"$A" shell "cmd package query-activities --brief -a android.intent.action.VIEW -d file:///sdcard/Download -t '*/*' 2>&1 | head -24" 2>&1 | tr -d '\r'

echo
echo "=== B. brief format, no type ==="
"$A" shell "cmd package query-activities --brief -a android.intent.action.VIEW -d file:///sdcard/Download 2>&1 | head -24" 2>&1 | tr -d '\r'

echo
echo "=== C. MIUI fileexplorer entry activities ==="
"$A" shell "cmd package resolve-activity --brief -a android.intent.action.MAIN -c android.intent.category.LAUNCHER com.android.fileexplorer 2>&1 | tail -2" 2>&1 | tr -d '\r'
"$A" shell "dumpsys package com.android.fileexplorer 2>/dev/null | grep -E 'android.intent.action.VIEW' -A6 | grep -E 'Scheme|Activity' | head -10" 2>&1 | tr -d '\r'

echo
echo "=== D. launch MT canary on the Download dir via -n ==="
"$A" shell "su -c 'am start --user 0 -a android.intent.action.VIEW -d file:///sdcard/Download -n bin.mt.plus.canary/bin.mt.plus.MainLightIcon 2>&1 | head -6'" 2>&1 | tr -d '\r'

echo
echo "=== E. top activity right after ==="
sleep 2
"$A" shell "dumpsys activity activities 2>/dev/null | grep -E 'topResumedActivity|mResumedActivity' | head -3" 2>&1 | tr -d '\r'

echo "=== DONE ==="
