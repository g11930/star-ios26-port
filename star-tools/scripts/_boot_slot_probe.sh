#!/bin/bash
export MSYS_NO_PATHCONV=1
A=/mnt/d/桌面/adb-fastboot/adb.exe

echo "=== boot slot / misc partitions ==="
"$A" shell "su -c 'ls -l /dev/block/by-name/ | grep -E \"boot|misc|hackios\"'" 2>&1 | tr -d '\r'

echo
echo "=== sizes ==="
"$A" shell "su -c 'for p in boot_a boot_b misc hackios_boot; do n=\$(readlink -f /dev/block/by-name/\$p 2>/dev/null); [ -n \"\$n\" ] && echo \"\$p -> \$n \$(blockdev --getsize64 \$n 2>/dev/null)\"; done'" 2>&1 | tr -d '\r'

echo
echo "=== magic of boot_a / boot_b (first 16 bytes) ==="
"$A" shell "su -c 'for p in boot_a boot_b; do echo -n \"\$p: \"; dd if=/dev/block/by-name/\$p bs=16 count=1 2>/dev/null | od -An -c | head -1; done'" 2>&1 | tr -d '\r'

echo
echo "=== current slot ==="
"$A" shell "getprop ro.boot.slot_suffix; getprop ro.boot.slot; su -c 'cat /proc/cmdline' 2>/dev/null | tr \" \" \"\n\" | grep -i slot" 2>&1 | tr -d '\r'

echo
echo "=== is there a loader payload marker in boot? ==="
"$A" shell "su -c 'dd if=/dev/block/by-name/boot_a bs=1 count=64 2>/dev/null | strings | head -3; echo ---; dd if=/dev/block/by-name/boot_a bs=512 skip=1 count=4 2>/dev/null | strings | head -5'" 2>&1 | tr -d '\r'
echo "=== DONE ==="
