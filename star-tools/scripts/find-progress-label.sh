#!/bin/bash
# Find which blob draws the boot progress label ("Configuring ... pipes").
F1=/root/star26/p22/root.apfs
F2=/root/star26/p22/src/rdimage
echo "=== root.apfs ==="
ls -la "$F1" 2>&1
grep -a -o -m 6 'Configuring[^\x00]\{0,48\}' "$F1" 2>/dev/null | head -6
echo "=== rdimage ==="
ls -la "$F2" 2>&1
grep -a -o -m 6 'Configuring[^\x00]\{0,48\}' "$F2" 2>/dev/null | head -6
echo "=== done ==="
