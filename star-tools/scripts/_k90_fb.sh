#!/bash
cd /root/k90-src || exit 1
echo "===== K90: newUserClient 出现位置 ====="
grep -rn "newUserClient" xnu/files/iokit/Kernel/ | head -20
echo
echo "===== K90: MiniIOMobileFramebuffer 里 class/start/register ====="
grep -n "OSDefineMetaClass\|kIOUserClientClassKey\|registerService\|setName\|IONewZero\|IOMobileFramebuffer::start" xnu/files/iokit/Kernel/MiniIOMobileFramebuffer.cpp | head -20
echo
echo "===== K90: UserClient 前 40 行 ====="
sed -n '1,40p' xnu/files/iokit/Kernel/MiniFramebufferUserClient.inc
echo
echo "===== 文件行数对比 ====="
wc -l xnu/files/iokit/Kernel/MiniIOMobileFramebuffer.cpp xnu/files/iokit/Kernel/MiniFramebufferUserClient.inc
