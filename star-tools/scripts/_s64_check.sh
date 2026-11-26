#!/bin/bash
F=/mnt/c/ios26/s64-logdump.bin
if [ ! -f "$F" ]; then
  echo "MISSING $F"
  ls -la /mnt/c/ios26/ | head -30
  exit 1
fi
echo "=== file ==="
ls -la "$F"
echo "=== tag counts ==="
strings -a "$F" | grep -c "SPWNVAL"
strings -a "$F" | grep -c "SPWNADOPT"
strings -a "$F" | grep -c "SPWNRET"
echo "=== backlight lines ==="
strings -a "$F" | grep -i "backlight" | head -30
echo "=== brightness lines ==="
strings -a "$F" | grep -i "brightness" | head -20
echo "=== star / disk marker (sanity: which run) ==="
strings -a "$F" | grep -E "StarDisk: published|AnnibaleDisk: published" | head -5
echo "=== process count marker ==="
strings -a "$F" | grep -E "Early boot complete|Cache sent to launchd" | head -5
