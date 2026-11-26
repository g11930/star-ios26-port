#!/bin/bash
set +e
# 从手机 sda24 logdump 取本轮日志（只读）
export MSYS_NO_PATHCONV=1
adb.exe shell "su -c 'dd if=/dev/block/sda24 bs=4096 count=64 2>/dev/null | base64'" 2>/dev/null | tr -d '\r\n ' | base64 -d > /tmp/logdump_cur.bin
echo "logdump size: $(stat -c%s /tmp/logdump_cur.bin 2>/dev/null)"
echo "########## 1. persona errors ##########"
strings -a /tmp/logdump_cur.bin 2>/dev/null | grep -i "persona\|kpersona" | sort | uniq -c | sort -rn | head -25
echo "########## 2. xpcproxy / spawn failures ##########"
strings -a /tmp/logdump_cur.bin 2>/dev/null | grep -i "xpcproxy\|spawn\|bootstrap\|look.?up\|service failed\|could not launch" | head -40
echo "########## 3. cfprefsd/configd/securityd/lsd mentions ##########"
strings -a /tmp/logdump_cur.bin 2>/dev/null | grep -iE "cfprefsd|configd|securityd|lsd|usermanagerd|containermanagerd" | head -30
echo "########## 4. new-format strings (current run marker) ##########"
strings -a /tmp/logdump_cur.bin 2>/dev/null | grep -iE "StarDisk: published|StarMsgProbe|waitq-diag|loader_return_after" | head -20
