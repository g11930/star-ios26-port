#!/bin/bash
OUT=/mnt/c/ios26/s90_provenance.out
: > "$OUT"
e(){ echo "$@" >> "$OUT"; }

e "=== MiniFramebufferUserClient.inc backup chain ==="
ls -la /root/star26/star-native/iokit/Kernel/MiniFramebufferUserClient.inc* >> "$OUT" 2>&1
e "--- md5 of each ---"
for f in /root/star26/star-native/iokit/Kernel/MiniFramebufferUserClient.inc*; do
  [ -f "$f" ] && md5sum "$f" >> "$OUT"
done

e ""
e "=== s90 kernel: does it have the metal setProperty strings? ==="
for s in "AnnibaleMetal" "IOAcceleratorES: published" "kAcceleratorPluginNameKey"; do
  a=$(strings -a /root/star26/s90/parts/kernel | grep -c "$s")
  b=$(strings -a /root/star26/s91/parts/kernel | grep -c "$s")
  c=$(strings -a /root/star26/s93/parts/kernel | grep -c "$s")
  e "  '$s': s90=$a s91=$b s93=$c"
done

e ""
e "=== build logs: which produced 1ad9a429? ==="
grep -rln "1ad9a429\|s90" /root/star26/*build*.log /mnt/d/桌面/star26-deps/*.log 2>/dev/null | head -10 >> "$OUT"

e ""
e "=== current source: metal guard state ==="
grep -n -A3 -B3 "setProperty(kAcceleratorPluginNameKey" /root/star26/star-native/iokit/Kernel/MiniFramebufferUserClient.inc >> "$OUT" 2>&1

e ""
e "=== current source: CS patch state ==="
grep -n "star_cs_keep_valid" /root/star26/star-native/bsd/kern/kern_cs.c >> "$OUT" 2>&1

e ""
e "=== DONE ==="
echo "OK $(wc -c < "$OUT") bytes"
