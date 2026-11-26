#!/bin/bash
OUT=/mnt/c/ios26/s90_vs_s91.out
: > "$OUT"
e(){ echo "$@" >> "$OUT"; }

e "=== s90 vs s91 parts md5 side-by-side ==="
for f in kernel loader.efi ramdisk rdimage cmdline memsize identity; do
  a=$(md5sum "/root/star26/s90/parts/$f" | cut -d' ' -f1)
  b=$(md5sum "/root/star26/s91/parts/$f" | cut -d' ' -f1)
  if [ "$a" = "$b" ]; then e "  $f SAME ($a)"; else e "  $f DIFF"; e "     s90=$a"; e "     s91=$b"; fi
done

e ""
e "=== cmdline diff ==="
diff -u /root/star26/s90/parts/cmdline /root/star26/s91/parts/cmdline >> "$OUT" 2>&1 || true

e ""
e "=== kernel strings: cs-related markers ==="
for s in star_cs_keep_valid CS_INITPAGE_BAD P28EXIT star_kv CS_SIGNED CODE_SIGNING; do
  a=$(strings -a /root/star26/s90/parts/kernel | grep -c "$s")
  b=$(strings -a /root/star26/s91/parts/kernel | grep -c "$s")
  e "  $s: s90=$a s91=$b"
done

e ""
e "=== kernel binary size ==="
stat -c '  s90 kernel %s' /root/star26/s90/parts/kernel >> "$OUT"
stat -c '  s91 kernel %s' /root/star26/s91/parts/kernel >> "$OUT"
stat -c '  s93 kernel %s' /root/star26/s93/parts/kernel >> "$OUT"

e ""
e "=== which kernel build does s90 correspond to? md5 across builds ==="
for d in /root/star26/s8* /root/star26/s9*; do
  [ -f "$d/parts/kernel" ] || continue
  m=$(md5sum "$d/parts/kernel" | cut -d' ' -f1)
  e "  $d $m"
done

e ""
e "=== DONE ==="
echo "OK $(wc -c < "$OUT") bytes"
