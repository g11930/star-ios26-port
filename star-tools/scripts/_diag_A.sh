#!/bin/bash
set +e
echo "########## 1. logd.plist ##########"
cat /root/star26/s58/work/root/LaunchDaemons/com.apple.logd.plist
echo "########## 2. logd_helper.plist ##########"
cat /root/star26/s58/work/root/LaunchDaemons/com.apple.logd_helper.plist
echo "########## 3. syslogd.plist ##########"
cat /root/star26/s58/work/root/LaunchDaemons/com.apple.syslogd.plist
echo "########## 4. root/var tree ##########"
find /root/star26/s58/work/root/var -maxdepth 4 2>/dev/null | head -60
echo "########## 5. root/private/var tree ##########"
find /root/star26/s58/work/root/private/var -maxdepth 4 2>/dev/null | head -60
echo "########## 6. find init.c / rc.jobs ##########"
find /root/star26/hackios-xnu-userland /root/star26/hackios-xnu-kernel -name "init.c" -o -name "rc.jobs" 2>/dev/null | head -20
echo "########## 7. find var.skel ##########"
find /root/star26 -name "var.skel" 2>/dev/null | head -10
echo "########## 8. s63 payload parts ##########"
ls -la /root/star26/s63/ 2>/dev/null | head -40
