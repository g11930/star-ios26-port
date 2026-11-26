#!/bin/bash
F=/mnt/d/桌面/adb-fastboot/fastboot.exe
echo "--- oem stop"
$F -s xnuloader oem stop
sleep 2
echo "--- devices"
$F devices
echo "--- boot"
$F -s xnuloader boot "C:/ios26/s182-boot.img"
sleep 3
echo "--- devices after"
$F devices