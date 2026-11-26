#!/bin/bash
A=/mnt/d/桌面/adb-fastboot/adb.exe
F=/mnt/d/桌面/adb-fastboot/fastboot.exe
$A reboot bootloader
for i in $(seq 1 25); do sleep 2; $F devices | grep -q "	fastboot" && break; done
$F devices | head -2
$F boot "C:/ios26/s184-boot.img" || { echo "boot refused"; exit 0; }
echo "booted; sampling"
for i in $(seq 1 10); do
  sleep 30
  $F -s xnuloader oem log > /dev/null 2>&1
  $F -s xnuloader get_staged "C:/ios26/s184a.bin" > /dev/null 2>&1
  strings -n 5 /mnt/c/ios26/s184a.bin > /tmp/s184a.txt
  m=$(grep -ac 'sync matched' /tmp/s184a.txt)
  th=$(grep -ac 'thumb [0-9]*:' /tmp/s184a.txt)
  ij=$(grep -ac 'iconservicesagent:' /tmp/s184a.txt)
  echo "T+$((i*30)) s  matched=$m thumbs=$th iconsvc-env=$ij  last=$(grep -a -oE '2025-12-10 [0-9:.]+\+0800' /tmp/s184a.txt | tail -1)"
  if [ "$m" -gt 0 ] || [ "$th" -gt 0 ]; then break; fi
done
echo "=== injections ==="
grep -a 'annibale-env:' /tmp/s184a.txt | sort -u | head -16
echo "=== thumb headers ==="
grep -a 'thumb [0-9]*:' /tmp/s184a.txt | head -6