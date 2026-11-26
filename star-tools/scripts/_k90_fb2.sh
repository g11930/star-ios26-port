#!/bash
cd /root/k90-src || exit 1
F1=xnu/files/iokit/Kernel/MiniIOMobileFramebuffer.cpp
F2=xnu/files/iokit/Kernel/MiniFramebufferUserClient.inc
echo "===== K90: newUserClient 出现位置 ====="
git show HEAD:$F1 | grep -n "newUserClient" | head -10
git show HEAD:$F2 | grep -n "newUserClient" | head -10
echo
echo "===== K90: class/发布相关 ====="
git show HEAD:$F1 | grep -n "OSDefineMetaClass\|kIOUserClientClassKey\|registerService\|setName(\|::start" | head -20
echo
echo "===== K90: UserClient 头部 ====="
git show HEAD:$F2 | sed -n '1,30p'
echo
echo "===== 行数对比 ====="
echo -n "K90 cpp: "; git show HEAD:$F1 | wc -l
echo -n "K90 inc: "; git show HEAD:$F2 | wc -l
echo -n "star cpp: "; wc -l < /root/star26/star-native/iokit/Kernel/MiniIOMobileFramebuffer.cpp
echo -n "star inc: "; wc -l < /root/star26/star-native/iokit/Kernel/MiniFramebufferUserClient.inc
