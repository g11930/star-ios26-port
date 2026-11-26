#!/bin/bash
F=/mnt/d/桌面/adb-fastboot/fastboot.exe
$F -s xnuloader oem log > /dev/null 2>&1
$F -s xnuloader get_staged "C:/ios26/iconprobe.bin" > /dev/null 2>&1
strings -n 5 /mnt/c/ios26/iconprobe.bin > /tmp/iconprobe.txt
echo "lines: $(wc -l < /tmp/iconprobe.txt)  last: $(grep -a -oE '2025-12-10 [0-9:.]+\+0800' /tmp/iconprobe.txt | tail -1)"
echo "=== iconservicesagent errors ==="
grep -a 'iconservicesagent' /tmp/iconprobe.txt | grep -ai 'fail\|error\|nil\|empty\|no ' | head -8
echo "=== icon-related errors (any process) ==="
grep -ai 'icon' /tmp/iconprobe.txt | grep -ai 'fail\|error\|unable\|missing\|nil\|0 bytes' | head -10
echo "=== shim draw stats for iconservicesagent ==="
grep -a 'annibalemetal\[iconservicesagent' /tmp/iconprobe.txt | tail -6
echo "=== SpringBoard icon loading ==="
grep -a 'SpringBoard' /tmp/iconprobe.txt | grep -ai 'icon' | tail -8