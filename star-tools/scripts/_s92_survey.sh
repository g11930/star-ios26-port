#!/bin/bash
# s92 调查：重建 s80..s92 各轮真实状态，聚焦 s90 vs s91/s92 的 A/B
D=/mnt/c/ios26
OUT=$D/survey.out
: > "$OUT"
e(){ echo "$@" >> "$OUT"; }

KEYS='StarDisk: published|IOAcceleratorES|star_cs|CS_INITPAGE|NOT_CODESIGNED|SecTask|cs_flags|containermanagerd|backboardd|SpringBoard|IOConsoleUsers|Metal|Annibale'

for n in 80 81 82 83 84 85 86 87 88 89 90 91 92; do
  for f in $D/s${n}-log.bin $D/s${n}-log2.bin $D/s${n}-staged.bin; do
    [ -f "$f" ] || continue
    sz=$(stat -c%s "$f")
    e ""
    e "############ s${n}  $(basename $f)  size=$sz"
    e "--- head 8 lines ---"
    strings -n 4 "$f" 2>/dev/null | head -8 >> "$OUT"
    e "--- key hits (count) ---"
    for k in 'StarDisk: published' 'AnnibaleDisk' 'IOAcceleratorES' 'CS_INITPAGE' 'NOT_CODESIGNED' 'SecTask' 'MetalPluginName' 'com.apple.backboardd' 'SpringBoard'; do
      c=$(strings -n 5 "$f" 2>/dev/null | grep -c -- "$k")
      e "  $(printf '%-28s' "$k") $c"
    done
  done
done
echo OK; ls -l "$OUT"
