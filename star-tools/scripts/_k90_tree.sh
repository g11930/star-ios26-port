#!/bash
cd /root/k90-src || exit 1
echo "===== git 跟踪的顶层目录 ====="
git ls-files | awk -F/ '{print $1}' | sort | uniq -c | sort -rn | head -15
echo
echo "===== bsd/dev 下的驱动 ====="
git ls-files | grep -E "^xnu/files/bsd/dev/" | head -20
echo
echo "===== iokit 相关补丁 ====="
git ls-files | grep -iE "iokit|framebuffer" | head -20
echo
echo "===== loader 里的显示/UI 实现 ====="
git ls-files | grep -E "^xnuloader/" | head -25
