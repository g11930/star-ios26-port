#!/bin/bash
F=/mnt/d/桌面/adb-fastboot/fastboot.exe
$F -s xnuloader boot "C:/ios26/s185-boot.img" || { echo refused; exit 0; }
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