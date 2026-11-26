#!/bash
L=/mnt/c/ios26/s100-live.bin
echo "===== 1) s100 open 三行 ====="
strings -n 8 "$L" | grep -E "s100 open|s100 started" | head -20
echo
echo "===== 2) 有任何 open 吗（计数）====="
echo -n "open asked: "; strings "$L" | grep -c "s100 open asked"
echo -n "open ->: "; strings "$L" | grep -c "s100 open ->"
echo -n "selector lines: "; strings -n 8 "$L" | grep -c "MiniIOMobileFramebuffer: .* selector"
echo
echo "===== 3) IOMobileFramebuffer 全部行 ====="
strings -n 8 "$L" | grep -E "MiniIOMobileFramebuffer" | head -12
echo
echo "===== 4) 健康计数 ====="
echo -n "error=22: "; strings "$L" | grep -c "error=22"
strings -n 8 "$L" | grep -oE "^2025-[0-9-]+ [0-9:]+" | tail -1
echo "===== DONE ====="
