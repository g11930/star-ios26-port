#!/bash
cd /root/k90-src || exit 1
echo "===== 关键词命中文件（全仓）====="
for k in newUserClient IOMobileFramebuffer IOFramebuffer IOServiceOpen IOAccelerator; do
  echo "--- $k"
  grep -rl "$k" --exclude-dir=.git . 2>/dev/null | head -8
done
echo
echo "===== 总文件数 / 目录深度 ====="
git ls-files | wc -l
git ls-files | grep -iE "display|framebuffer|iomfb|metal" | head -15
