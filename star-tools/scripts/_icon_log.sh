#!/bin/bash
for f in /mnt/c/ios26/s165d-live.bin /mnt/c/ios26/s164d-live.bin; do
  [ -f "$f" ] || continue
  strings -n 5 "$f" > /tmp/x.txt
  echo "=== $f ($(wc -l < /tmp/x.txt) lines) ==="
  grep -a -i -E 'iconservices|cuicatalog|assets\.car|icon.*(fail|error|nil|missing)|image.*(decode|failed)|CAFilter|liquid' /tmp/x.txt | head -12
done
</>
