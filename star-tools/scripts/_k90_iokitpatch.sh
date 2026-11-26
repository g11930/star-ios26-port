#!/bash
cd /root/k90-src || exit 1
echo "########## 25 IOService.cpp.patch ##########"
git show HEAD:xnu26/patches/25-iokit%Kernel%IOService.cpp.patch | head -80
echo
echo "########## 27 IOUserClient.cpp.patch ##########"
git show HEAD:xnu26/patches/27-iokit%Kernel%IOUserClient.cpp.patch | head -120
