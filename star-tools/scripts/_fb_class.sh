#!/bash
R=/root/sys-root
echo "===== rootfs 里引用这两个类名的可执行文件 ====="
for n in AppleH1CLCD AppleM2CLCD; do
  echo "--- $n"
  grep -rl "$n" $R/usr/libexec $R/System/Library/CoreServices 2>/dev/null | head -4
done
echo
echo "===== backboardd / SpringBoard 内出现次数 ====="
for n in AppleH1CLCD AppleM2CLCD; do
  printf '%-16s bbd=%s sb=%s\n' "$n" \
    "$(strings -n 6 /root/backboardd.bin | grep -c -F "$n")" \
    "$(strings -n 6 $R/System/Library/CoreServices/SpringBoard.app/SpringBoard | grep -c -F "$n")"
done
echo
echo "===== 全 rootfs 引用 AppleM2CLCD 的文件（限 8）====="
grep -rl "AppleM2CLCD" $R 2>/dev/null | head -8
</bash>
