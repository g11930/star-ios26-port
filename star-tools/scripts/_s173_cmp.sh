#!/bin/bash
U=/root/star26/s111/work/rootbuild/root
echo "=== rc.jobs.s171 全文 ==="
cat "$U/etc/rc.jobs.s171" 2>/dev/null
echo
echo "=== 注入文件的修改时间 ==="
ls -la --time-style=+"%m-%d_%H:%M" "$U/etc/sbmetal-late" "$U/lib/libannibale-sbmetal-experiment.dylib" "$U/lib/libsbtrace.dylib" 2>/dev/null
echo
echo "=== 各镜像里是否含 triangle_app / sbmetal / trialwake ==="
for n in 172 173 174 175 176 177 178 180 185 190; do
  f=/mnt/c/ios26/s$n-boot.img
  [ -f "$f" ] || continue
  t=$(grep -c "triangle_app" "$f" 2>/dev/null || true)
  s=$(grep -c "sbmetal-late" "$f" 2>/dev/null || true)
  w=$(grep -c "trialwake" "$f" 2>/dev/null || true)
  e=$(grep -c "annibale-sbmetal-experiment" "$f" 2>/dev/null || true)
  printf "  s%-4s triangle=%-3s sbmetal-late=%-3s trialwake=%-3s experiment=%-3s  size=%s\n" "$n" "$t" "$s" "$w" "$e" "$(stat -c%s "$f")"
done
