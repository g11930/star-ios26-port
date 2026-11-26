#!/bin/bash
OUT=/mnt/c/ios26/source_state.out
: > "$OUT"
e(){ echo "$@" >> "$OUT"; }
T=/root/star26/star-native

e "=== backup chains of files changed after s90 ==="
for f in bsd/kern/kern_cs.c bsd/kern/mach_loader.c bsd/kern/kern_minimac.c iokit/Kernel/MiniFramebufferUserClient.inc; do
  e "--- $f ---"
  ls -la "$T/$f"* >> "$OUT" 2>&1
  for b in "$T/$f".*; do
    [ -f "$b" ] && md5sum "$b" >> "$OUT"
  done
done

e ""
e "=== mach_loader s92 probe code present in current source? ==="
grep -n "star_cs_probe\|star_cs_keep_valid\|CS_INITPAGE_BAD" "$T/bsd/kern/mach_loader.c" >> "$OUT" 2>&1 | head -20

e ""
e "=== s90 kernel strings: does it have s92 probe? ==="
for s in star_cs_probe star_cs_keep_valid CS_INITPAGE_BAD; do
  a=$(strings -a /root/star26/s90/parts/kernel | grep -c "$s")
  b=$(strings -a /root/star26/s91/parts/kernel | grep -c "$s")
  c=$(strings -a /root/star26/s92/parts/kernel | grep -c "$s")
  e "  $s: s90=$a s91=$b s92=$c"
done

e ""
e "=== DONE ==="
echo "OK $(wc -c < "$OUT") bytes"
