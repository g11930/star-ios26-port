#!/bin/bash
for L in /mnt/d/ios26/s208-now.bin /mnt/d/ios26/s215-mid-061113.bin /mnt/d/ios26/s208-final-054514.bin; do
  [ -f "$L" ] || continue
  echo "################ $L"
  echo "--- adreno lines (unique) ---"
  grep -a "adreno:" "$L" 2>/dev/null | sed 's/^.*adreno:/adreno:/' | sort -u | head -40
  echo "--- gpu kept / STAYS / speed ---"
  grep -a -E "THE GPU STAYS|the speed wanted|votes:|gfx\.lvl|cx\.lvl|mx\.lvl|bus resources" "$L" 2>/dev/null | head -12
  echo
done
