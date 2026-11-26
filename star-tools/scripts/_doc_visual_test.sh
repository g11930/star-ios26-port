#!/bin/bash
export MSYS_NO_PATHCONV=1
A=/mnt/d/桌面/adb-fastboot/adb.exe

echo "=== A. DocumentsUI with SAF primary:Download ==="
"$A" shell "su -c 'am start --user 0 -a android.intent.action.VIEW -d \"content://com.android.externalstorage.documents/document/primary:Download\" -n com.google.android.documentsui/com.android.documentsui.files.FilesActivity 2>&1 | head -4'" 2>&1 | tr -d '\r'
sleep 4
"$A" shell "screencap -p /sdcard/o_doc.png" 2>&1 | tr -d '\r' | grep -viE 'warning|display' | head -2
"$A" pull /sdcard/o_doc.png C:/ios26/o_doc.png 2>&1 | tr -d '\r' | tail -1

echo
echo "=== B. MIUI with file:// + action VIEW on its real VIEW activity ==="
"$A" shell "su -c 'dumpsys package com.android.fileexplorer | grep -n \"android.intent.action.VIEW\" -A4 | grep -E \"Activity|Scheme|name=\" | head -12'" 2>&1 | tr -d '\r'
echo "=== DONE ==="
