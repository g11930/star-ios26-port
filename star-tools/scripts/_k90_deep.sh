#!/bash
cd /root/k90-src || exit 1
echo "===== common/devices ====="
ls common/devices | head -20
echo
echo "===== 找 framebuffer/metal/accelerator 关键词 ====="
grep -rliE "IOMobileFramebuffer|IOAccelerator|backboardd|WindowServer" --exclude-dir=.git . | head -20
echo
echo "===== xl 目录 ====="
ls xl | head -20
echo
echo "===== README 摘要 ====="
head -40 README.md
