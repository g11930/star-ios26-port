#!/bin/bash
# Pull the logdump partition (sda24, 64 MiB) over adb without exec-out, which mangles binary.
# Base64 on the device side, decoded here. The kernel log the loader staged sits at the front.
export MSYS_NO_PATHCONV=1
A=/d/桌面/adb-fastboot/adb.exe
OUT=/c/ios26/p21-logdump.b64

timeout 180 "$A" shell "su -c 'dd if=/dev/block/sda24 bs=4096 count=4096 2>/dev/null | base64'" > "$OUT" 2>/dev/null
echo "b64 bytes: $(wc -c < "$OUT")"
tr -d '\r\n ' < "$OUT" | base64 -d > /c/ios26/p21-logdump.bin 2>/dev/null
ls -la /c/ios26/p21-logdump.bin
echo "=== printable head ==="
head -c 4000 /c/ios26/p21-logdump.bin | tr -c '[:print:]\n' '.' | head -40
