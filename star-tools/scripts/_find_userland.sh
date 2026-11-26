#!/bash
echo "===== 找 userland 源码目录 ====="
find /root -maxdepth 3 -type d -iname "*userland*" 2>/dev/null | head -10
echo
echo "===== 找含 IOServiceMatching 的用户态文件 ====="
grep -rl "IOServiceMatching" /root --include=*.c --include=*.m --include=*.h --include=*.cpp 2>/dev/null | grep -v "star-native" | head -20
echo
echo "===== 找 'say' trace 前缀实现 ====="
grep -rn "trace: %s IOServiceMatching" /root 2>/dev/null | head -5
