#!/bash
L=/mnt/c/ios26/s99-live.bin
echo "===== 1) 属性是否在注册表 ====="
strings -n 8 "$L" | grep -E "props after register" | head -3
echo
echo "===== 2) 四路匹配对照 ====="
strings -n 8 "$L" | grep -E "IOSvcProbe" | head -8
echo
echo "===== 3) 其它 IOAcceleratorES 行 ====="
strings -n 8 "$L" | grep -E "IOAcceleratorES" | head -6
echo
echo "===== 4) 计数 ====="
echo -n "error=22: "; strings "$L" | grep -c "error=22"
echo -n "props MISSING: "; strings "$L" | grep -c "MISSING"
echo
echo "===== 5) 尾部时间 ====="
strings -n 8 "$L" | grep -oE "^2025-[0-9-]+ [0-9:]+" | tail -1
echo "===== DONE ====="
