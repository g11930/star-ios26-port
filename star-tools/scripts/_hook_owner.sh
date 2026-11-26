#!/bash
echo "===== 哪个 dylib 含 detectDisplays 钩子 ====="
for f in $(find /root/star26 /root/star-build -maxdepth 6 -name "libannibale*.dylib" 2>/dev/null | head -20); do
  c=$(strings -n 8 "$f" 2>/dev/null | grep -c "detectDisplays")
  [ "$c" != "0" ] && echo "$f : $c"
done
echo
echo "===== 现有 inject.conf 里含 sbmetal 的（即当前用的那份）====="
for f in $(find /root -maxdepth 6 -name inject.conf 2>/dev/null); do
  if grep -q sbmetal "$f" 2>/dev/null; then echo "== $f"; cat "$f"; fi
done
echo "===== DONE ====="
</bash>
