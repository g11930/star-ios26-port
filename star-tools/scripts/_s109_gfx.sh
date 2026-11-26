#!/bash
L=/mnt/c/ios26/s109-live.bin
echo "===== 渲染相关关键字计数 ====="
for k in sbmetal26 annibale Annibale softpipe rwa_software IOSurface "would load"; do
  printf '%-14s %s\n' "$k" "$(strings "$L" | grep -c -F "$k")"
done
echo
echo "===== annibale 相关行 ====="
strings -n 10 "$L" | grep -i annibale | head -12
echo
echo "===== libannibale 注入痕迹 ====="
strings -n 10 "$L" | grep -iE "libannibale|inject" | head -10
echo "===== DONE ====="
</bash>
