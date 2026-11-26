#!/bin/bash
A=/mnt/d/桌面/adb-fastboot/adb.exe
F=/mnt/d/桌面/adb-fastboot/fastboot.exe
IMG="C:/ios26/s182-boot.img"

echo "waiting for the phone (power-cycle it now)"
for i in $(seq 1 60); do
  if $A devices | grep -q "	device"; then echo "android up"; break; fi
  if $F devices | grep -q "	fastboot"; then
    echo "fastboot up: $($F devices | head -1)"
    $F reboot > /dev/null 2>&1
  fi
  sleep 5
done

$A devices | head -3
$A reboot bootloader
for i in $(seq 1 25); do sleep 2; $F devices | grep -q "	fastboot" && break; done
$F devices
$F boot "$IMG" || { echo "boot refused"; exit 0; }
start=$(date +%s)
for i in $(seq 1 18); do
  sleep 30
  $F -s xnuloader oem screenshot > /dev/null 2>&1
  $F -s xnuloader get_staged "C:/ios26/t3-frame.raw" > /dev/null 2>&1
  b=$(python3 /mnt/d/桌面/star26-deps/scripts/fb2png.py /mnt/c/ios26/t3-frame.raw /mnt/c/ios26/t3-frame.png 2>&1 | grep -oE '[0-9]+ bytes' | head -1 | grep -oE '[0-9]+')
  now=$(date +%s)
  echo "T+$((now-start)) s  frame ${b:-?} bytes"
  if [ -n "$b" ] && [ "$b" -gt 100000 ]; then
    echo "DESKTOP at T+$((now-start)) s (boot 1 of this image was ~T+300 s)"
    $F -s xnuloader oem log > /dev/null 2>&1
    $F -s xnuloader get_staged "C:/ios26/s182-second.bin" > /dev/null 2>&1
    strings -n 5 /mnt/c/ios26/s182-second.bin > /tmp/s182_2.txt
    echo "ir3 waits: $(grep -ac 'ir3 wait' /tmp/s182_2.txt)  thumbs: $(grep -ac 'thumb [0-9]*:' /tmp/s182_2.txt)"
    break
  fi
done