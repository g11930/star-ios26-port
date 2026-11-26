#!/bin/bash
A=/mnt/d/桌面/adb-fastboot/adb.exe
F=/mnt/d/桌面/adb-fastboot/fastboot.exe
$A reboot bootloader
for i in $(seq 1 25); do sleep 2; $F devices | grep -q fastboot && break; done
$F devices | head -2
$F boot "C:/ios26/s182-boot.img" || { echo "boot refused"; exit 0; }
start=$(date +%s)
for i in $(seq 1 20); do
  sleep 30
  $F -s xnuloader oem screenshot > /dev/null 2>&1
  $F -s xnuloader get_staged "C:/ios26/t4-frame.raw" > /dev/null 2>&1
  b=$(python3 /mnt/d/桌面/star26-deps/scripts/fb2png.py /mnt/c/ios26/t4-frame.raw /mnt/c/ios26/t4-frame.png 2>&1 | grep -oE '[0-9]+ bytes' | head -1 | grep -oE '[0-9]+')
  now=$(date +%s)
  echo "T+$((now-start)) s frame ${b:-?}"
  if [ -n "$b" ] && [ "$b" -gt 100000 ]; then
    echo "DESKTOP at T+$((now-start)) s"
    $F -s xnuloader oem log > /dev/null 2>&1
    $F -s xnuloader get_staged "C:/ios26/s182-second.bin" > /dev/null 2>&1
    strings -n 5 /mnt/c/ios26/s182-second.bin > /tmp/s182_2.txt
    echo "ir3 waits: $(grep -ac 'ir3 wait' /tmp/s182_2.txt)"
    grep -a 'ir3 wait' /tmp/s182_2.txt | tail -2
    cp /mnt/c/ios26/t4-frame.png /mnt/c/ios26/second-boot-desktop.png
    break
  fi
done