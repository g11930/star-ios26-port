#!/bin/bash
for L in /mnt/d/ios26/now-085730.bin /mnt/d/ios26/now-085807.bin; do
  echo "=== $L ==="
  printf "size: "; stat -c%s "$L"
  printf "last ts: "; grep -a -oE "[0-9]{2}:[0-9]{2}:[0-9]{2}\.[0-9]{3}" "$L" | tail -1
  echo "last pac traps:"
  grep -a "pac: traps=" "$L" | tail -2
  printf "SpringBoard lines: "; grep -a -c "SpringBoard" "$L"
  printf "pac page lines: "; grep -a -c "pac: page" "$L"
  printf "launchd lines: "; grep -a -c "launchd" "$L"
  printf "panic/halt: "; grep -a -c -E "panic:|haltRestart" "$L"
done
