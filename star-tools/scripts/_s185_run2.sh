#!/bin/bash
A=/mnt/d/桌面/adb-fastboot/adb.exe
F=/mnt/d/桌面/adb-fastboot/fastboot.exe
$F -s xnuloader oem stop > /dev/null 2>&1
echo "stopped, waiting android"
for i in $(seq 1 60); do sleep 3; $A devices | grep -q "	device" && break; done
$A devices | head -3
$A reboot bootloader
for i in $(seq 1 25); do sleep 2; $F devices | grep -q "	fastboot" && break; done
$F devices | head -2
$F boot "C:/ios26/s185-boot.img" || { echo refused; exit 0; }
for i in $(seq 1 8); do
  sleep 30
  $F -s xnuloader oem log > /dev/null 2>&1
  $F -s xnuloader get_staged "C:/ios26/s185a.bin" > /dev/null 2>&1
  strings -n 5 /mnt/c/ios26/s185a.bin > /tmp/s185a.txt
  th=$(grep -ac 'thumb [0-9]*:' /tmp/s185a.txt)
  echo "T+$((i*30)) s thumbs=$th  last=$(grep -a -oE '2025-12-10 [0-9:.]+\+0800' /tmp/s185a.txt | tail -1)"
  if [ "$th" -gt 0 ]; then break; fi
done
echo "=== thumb headers ==="
grep -a 'thumb [0-9]*:' /tmp/s185a.txt | head -6