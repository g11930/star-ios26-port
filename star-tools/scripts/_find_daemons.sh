#!/bash
R=/root/sys-root
echo "===== 关键守护进程是否存在 ====="
for n in backboardd WindowServer displayd SkyLight oscard runningboardd SpringBoard; do
  hit=$(find $R -maxdepth 5 -name "$n" -type f 2>/dev/null | head -2)
  printf '%-16s %s\n' "$n" "${hit:-MISSING}"
done
echo
echo "===== LaunchDaemons 里和显示相关的 plist ====="
ls $R/System/Library/LaunchDaemons 2>/dev/null | grep -iE "display|window|backboard|sky|oscar|graphics" | head -20
echo
echo "===== 我方可执行文件列表（/usr/libexec 里有无 windowserver 类）====="
ls $R/usr/libexec 2>/dev/null | grep -iE "window|display|sky|render" | head -10
