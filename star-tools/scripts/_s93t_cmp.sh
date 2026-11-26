#!/bin/bash
# S93t: 对比 s90/s91/s92 三代日志
for n in s90 s91 s92; do
  B=/mnt/c/ios26/$n-log.bin
  [ "$n" = s92 ] && B=/mnt/c/ios26/s92-staged.bin
  echo "############ $n : $B ############"
  if [ ! -f "$B" ]; then echo "  (missing)"; continue; fi
  stat -c "  size=%s mtime=%y" "$B"
  echo "  -- total lines: $(strings -a "$B" | wc -l)"
  echo "  -- STARX count: $(strings -a "$B" | grep -c STARX)"
  echo "  -- CS_INITPAGE count: $(strings -a "$B" | grep -c CS_INITPAGE)"
  echo "  -- IOAcceleratorES count: $(strings -a "$B" | grep -c IOAcceleratorES)"
  echo "  -- kernel-phase markers:"
  strings -a "$B" | grep -E 'version|Darwin|XNU|pmap|kalloc|StarDisk|AppleDisk|AnnibaleDisk|splash|fb_flip|panic|assert' | head -12
  echo "  -- IOAcceleratorES lines:"
  strings -a "$B" | grep 'IOAcceleratorES' | head -12
  echo "  -- STARX tail:"
  strings -a "$B" | grep STARX | tail -12
  echo
done
echo "=== DONE ==="
