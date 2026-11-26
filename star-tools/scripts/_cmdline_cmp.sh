#!/bin/bash
echo "########## OUR s70 cmdline ##########"
tr -d '\0' < /root/star26/s70/parts/cmdline
echo
echo
echo "########## WARSAW v37 (能进桌面) cmdline ##########"
grep -a "boot-args" /root/ref/warsaw/docs/v37/log-tail.txt | head -1 | sed 's/.*boot-args = //'
echo
echo "########## WARSAW v92 (主屏桌面) cmdline ##########"
grep -rha "boot-args" /root/ref/warsaw/docs/ 2>/dev/null | grep -oE "debug=0x[0-9a-f]+ .*" | head -3
echo
echo "########## 逐 key 差异（对齐到空格分隔） ##########"
OUR=$(tr -d '\0' < /root/star26/s70/parts/cmdline)
WAR=$(grep -a "boot-args" /root/ref/warsaw/docs/v37/log-tail.txt | head -1 | sed 's/.*boot-args = //')
echo "--- 只在 OUR ---"
for k in $OUR; do echo "$WAR" | grep -qw "${k%%=*}" || echo "$k"; done
echo "--- 只在 WARSAW ---"
for k in $WAR; do echo "$OUR" | grep -qw "${k%%=*}" || echo "$k"; done
