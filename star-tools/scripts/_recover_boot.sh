#!/bin/bash
F=/mnt/d/桌面/adb-fastboot/fastboot.exe
$F -s xnuloader boot "C:/ios26/s182-boot.img" 2>&1 | tail -3
if [ $? -ne 0 ]; then
  echo "--- retry after oem stop"
  $F -s xnuloader oem stop > /dev/null 2>&1
  sleep 2
  $F -s xnuloader boot "C:/ios26/s182-boot.img" 2>&1 | tail -3
fi