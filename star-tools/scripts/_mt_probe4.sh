#!/bin/bash
# Read-only: how does each file manager register itself for opening a directory?
export MSYS_NO_PATHCONV=1
A=/mnt/d/桌面/adb-fastboot/adb.exe

echo "=== MT canary: launcher activity ==="
"$A" shell "cmd package resolve-activity --brief -a android.intent.action.MAIN -c android.intent.category.LAUNCHER bin.mt.plus.canary 2>&1" 2>&1 | tr -d '\r'

echo
echo "=== MT canary: VIEW intent filters ==="
"$A" shell "dumpsys package bin.mt.plus.canary 2>/dev/null | grep -n -A14 'android.intent.action.VIEW' | head -60" 2>&1 | tr -d '\r'

echo
echo "=== MT canary: exported activities ==="
"$A" shell "dumpsys package bin.mt.plus.canary 2>/dev/null | grep -E 'Activity #|^ *[a-z0-9_.]+/[A-Za-z0-9_.]+' | head -20" 2>&1 | tr -d '\r'

echo
echo "=== MIUI file explorer registration ==="
"$A" shell "dumpsys package com.android.fileexplorer 2>/dev/null | grep -n -B2 -A10 'resource/folder' | head -30" 2>&1 | tr -d '\r'

echo
echo "=== DocumentsUI registration ==="
"$A" shell "dumpsys package com.google.android.documentsui 2>/dev/null | grep -n -B2 -A10 'resource/folder' | head -30" 2>&1 | tr -d '\r'

echo
echo "=== query-activities with several mime shapes ==="
for shape in "resource/folder" "*/*"; do
  echo "--- type=$shape ---"
  "$A" shell "cmd package query-activities -a android.intent.action.VIEW -d file:///sdcard/Download -t '$shape' 2>&1 | grep packageName | sort -u" 2>&1 | tr -d '\r'
done
echo "--- no type ---"
"$A" shell "cmd package query-activities -a android.intent.action.VIEW -d file:///sdcard/Download 2>&1 | grep packageName | sort -u" 2>&1 | tr -d '\r'
echo "--- with DEFAULT category ---"
"$A" shell "cmd package query-activities -a android.intent.action.VIEW -c android.intent.category.DEFAULT -d file:///sdcard/Download 2>&1 | grep packageName | sort -u" 2>&1 | tr -d '\r'

echo "=== DONE ==="
