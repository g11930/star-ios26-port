#!/bin/bash
for f in /root/star26/s34/verify/root/etc/inject.conf /root/star26/s34/work/root/etc/inject.conf /root/star26/s39/work/root/etc/inject.conf; do
  echo "--- $f"
  [ -f "$f" ] && grep -n 'experiment\|sbmetal' "$f" | head -4
done
echo "=== any inject.conf in trees ==="
find /root/star26 -name 'inject.conf*' -newermt '2026-01-01' 2>/dev/null | head -10
</