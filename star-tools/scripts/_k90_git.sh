#!/bash
cd /root/k90-src || exit 1
echo "===== git 概况 ====="
git log --oneline | head -15
echo
echo "===== 仓库结构 ====="
find . -maxdepth 3 -type d -not -path "./.git/*" | sed -n '1,60p'
echo
echo "===== 显示/iokit 相关目录 ====="
find . -maxdepth 5 -type d \( -iname "*iokit*" -o -iname "*display*" -o -iname "*gpu*" -o -iname "*graphics*" \) -not -path "./.git/*" | head -20
