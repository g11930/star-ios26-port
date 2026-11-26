#!/bin/bash
NM=/root/star-build/xnu-deps/host/bin/nm
OUT=/mnt/c/ios26/s93_nm_check.out
: > "$OUT"
e(){ echo "$@" >> "$OUT"; }
for tag in s90 s91 s92 s93 s94; do
  K=/root/star26/$tag/parts/kernel
  [ -f "$K" ] || continue
  U=/root/star26/$tag/parts/kernel.nm.tmp
  e "=== $tag ($(stat -c %s $K) bytes, md5 $(md5sum $K | cut -c1-12)) ==="
  e -n "  _star_cs_keep_valid symbol : "
  # stripped kernel has no symtab; try unstripped build copies by md5 match below
  e "$(strings -a $K | grep -c '^star_cs_keep_valid$') strings"
done

e ""
e "=== unstripped builds in BUILD dir: which tags still exist? ==="
find /root/star26 -path '*/mach.release.bcm2837.unstripped.noctf' -printf '%TY-%Tm-%Td %TH:%TM  %s  %p\n' 2>/dev/null | sort -r | head -10 >> "$OUT"

e ""
e "=== nm on the CURRENT build unstripped (s94) ==="
U=/root/star26/star-native/BUILD/obj/RELEASE_ARM64_BCM2837/mach.release.bcm2837.unstripped.noctf
e -n "  _star_cs_keep_valid : "; "$NM" "$U" 2>/dev/null | grep -c '_star_cs_keep_valid'
e -n "  _star_cs_probe     : "; "$NM" "$U" 2>/dev/null | grep -c '_star_cs_probe'

e ""
e "=== s93 kernel: raw grep for the symbol string w/ underscore ==="
grep -aob '_star_cs_keep_valid' /root/star26/s93/parts/kernel | head -3 >> "$OUT"
echo "(end)" >> "$OUT"
e ""
e "=== s91 vs s93 vs s94: Metal unconditional setProperty proof via IOLog strings ==="
for tag in s90 s91 s93 s94; do
  K=/root/star26/$tag/parts/kernel
  e "$tag: IOAcceleratorES published = $(strings -a $K | grep -c 'IOAcceleratorES: published'), self-test = $(strings -a $K | grep -c 'self-test %u')"
done
e ""
e "=== DONE ==="
echo "OK $(wc -c < "$OUT") bytes"
