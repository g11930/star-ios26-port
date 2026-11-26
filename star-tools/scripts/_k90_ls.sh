#!/bash
echo "===== /root/k90-src 顶层 ====="
ls /root/k90-src 2>/dev/null | head -40
echo
echo "===== 是否 git 仓库 / 补丁目录 ====="
ls -d /root/k90-src/.git 2>/dev/null && echo "git repo"
find /root/k90-src -maxdepth 2 -name "*.patch" 2>/dev/null | head -10
echo
echo "===== 与显示相关的文件 ====="
find /root/k90-src -maxdepth 4 \( -iname "*framebuffer*" -o -iname "*display*" -o -iname "*backboard*" \) 2>/dev/null | head -20
