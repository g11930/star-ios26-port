#!/bin/bash
# s90 vs s91 vs s92 逐行对照：SecTask / NOT_CODESIGNED / IOAcceleratorES / cs
D=/mnt/c/ios26
OUT=$D/survey2.out
: > "$OUT"
e(){ echo "$@" >> "$OUT"; }

dump(){
  local f="$1" tag="$2"
  e ""
  e "################ $tag  ($f)"
  e "--- SecTask all ---"
  strings -n 5 "$f" | grep -n -- "SecTask" >> "$OUT"
  e "--- NOT_CODESIGNED / container_error ---"
  strings -n 5 "$f" | grep -n -E "NOT_CODESIGNED|container_error|Code=-98|98\)" | head -30 >> "$OUT"
  e "--- IOAcceleratorES all ---"
  strings -n 5 "$f" | grep -n -- "IOAcceleratorES" >> "$OUT"
  e "--- cs_flags / CS_VALID / codesign ---"
  strings -n 5 "$f" | grep -n -E "cs_flags|CS_VALID|CODE SIGNING|amfi|AMFI|cs_blob" | head -40 >> "$OUT"
  e "--- MetalPlugin / Annibale ---"
  strings -n 5 "$f" | grep -n -E "MetalPlugin|AnnibaleMetal|annibale" | head -30 >> "$OUT"
}

dump "$D/s90-log.bin" "s90"
dump "$D/s91-log.bin" "s91"
dump "$D/s92-staged.bin" "s92"

echo OK; ls -l "$OUT"
