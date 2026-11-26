#!/bash
cd /root/k90-src || exit 1
echo "===== 全仓 regtrace 引用 ====="
git grep -n "regtrace" HEAD -- xnu xnu26 tools 2>/dev/null | head -20
echo
echo "===== K90 IOPlatformExpert / IOStartIOKit 补丁（发布相关）====="
git show "HEAD:xnu26/patches/24-iokit%Kernel%IOPlatformExpert.cpp.patch" | head -60
echo
echo "===== K90 MiniFramebuffer 相关 patch 是否存在 ====="
git ls-files | grep -iE "miniframebuffer|MiniIOMobile" | head
