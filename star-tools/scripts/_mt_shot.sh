#!/bin/bash
export MSYS_NO_PATHCONV=1
A=/mnt/d/桌面/adb-fastboot/adb.exe
"$A" shell "screencap -p /sdcard/mt_probe.png" 2>&1 | tr -d '\r'
"$A" pull /sdcard/mt_probe.png C:/ios26/mt_probe.png 2>&1 | tr -d '\r' | tail -2
ls -la /mnt/c/ios26/mt_probe.png
