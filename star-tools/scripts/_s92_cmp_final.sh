#!/bin/bash
# 决定性命中：cmdline 全文 + kernel md5 逐轮对比
OUT=/mnt/c/ios26/cmp_final.out
: > "$OUT"
e(){ echo "$@" >> "$OUT"; }

for n in 87 88 89 90 91 92; do
  d=/root/star26/s$n/parts
  e "############ s$n"
  e "--- cmdline ($(stat -c%s $d/cmdline) B) ---"
  cat "$d/cmdline" >> "$OUT"; e ""
  e "--- kernel md5=$(md5sum $d/kernel | cut -d' ' -f1)  size=$(stat -c%s $d/kernel)"
  e "--- loader.efi md5=$(md5sum $d/loader.efi | cut -d' ' -f1)  size=$(stat -c%s $d/loader.efi)"
  e "--- ramdisk md5=$(md5sum $d/ramdisk | cut -d' ' -f1)"
  e "--- rdimage md5=$(md5sum $d/rdimage | cut -d' ' -f1)"
  e ""
done

echo OK; ls -l "$OUT"
