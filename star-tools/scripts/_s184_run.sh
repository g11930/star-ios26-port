#!/bin/bash
A=/mnt/d/桌面/adb-fastboot/adb.exe
F=/mnt/d/桌面/adb-fastboot/fastboot.exe
# device may be in iOS (loader) or android; get to ABL fastboot then boot
if ! $F devices | grep -q "	fastboot"; then
  $A reboot bootloader 2>/dev/null
fi
for i in $(seq 1 25); do sleep 2; $F devices | grep -q "	fastboot" && break; done
$F devices | head -2
$F boot "C:/ios26/s184-boot.img" || { echo "boot refused (kernel running?)"; exit 0; }
sleep 220
$F -s xnuloader oem log > /dev/null 2>&1
$F -s xnuloader get_staged "C:/ios26/s184a.bin" > /dev/null 2>&1
strings -n 5 /mnt/c/ios26/s184a.bin > /tmp/s184a.txt
echo "=== injections ==="
grep -a 'annibale-env:' /tmp/s184a.txt | sort -u | head -16
echo "=== matched / thumbs ==="
echo "matched: $(grep -ac 'sync matched' /tmp/s184a.txt)  thumbs: $(grep -ac 'thumb [0-9]*:' /tmp/s184a.txt)"
grep -a 'sync matched' /tmp/s184a.txt | head -3
grep -a 'thumb [0-9]*:' /tmp/s184a.txt | head -5
echo "last ts: $(grep -a -oE '2025-12-10 [0-9:.]+\+0800' /tmp/s184a.txt | tail -1)"