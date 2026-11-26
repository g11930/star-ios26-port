#!/bash
cd /root/star26/star-native || exit 1
echo "=== trace 打印 IOServiceMatching 的位置 ==="
grep -rn "IOServiceMatching" --include=*.c --include=*.cpp --include=*.inc . | grep -i "trace\|say\|IOLog" | head -10
echo
echo "=== 所有 IOServiceMatching 引用 ==="
grep -rn "IOServiceMatching" --include=*.c --include=*.cpp --include=*.inc . | head -15
echo
echo "=== 是否存在 userland shim ==="
ls userland 2>/dev/null | head
