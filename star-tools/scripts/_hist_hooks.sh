#!/bash
echo "===== 历史日志中 annibale 钩子是否跑过 ====="
for t in s40 s44 s47 s48 s49 s50 s51 s54 s29 s30; do
  f=/mnt/c/ios26/$t-live.bin
  [ -f "$f" ] || continue
  a=$(strings -n 8 "$f" | grep -c "annibale lib loaded")
  b=$(strings -n 8 "$f" | grep -c "window server hooks")
  c=$(strings -n 8 "$f" | grep -c "_detectDisplays")
  d=$(strings -n 8 "$f" | grep -c "MiniIOMobileFramebuffer: .*selector")
  printf '%s lib_loaded=%s hooks=%s detect=%s fb_selector=%s\n' "$t" "$a" "$b" "$c" "$d"
done
echo
echo "===== 任一老日志里 hooks 的实际行 ====="
for t in s54 s51 s50 s48; do
  f=/mnt/c/ios26/$t-live.bin
  [ -f "$f" ] || continue
  echo "-- $t"
  strings -n 8 "$f" | grep -F "annibale" | grep -iE "hooks|detect|camtl|loaded" | head -6
done
echo "===== DONE ====="
</bash>
