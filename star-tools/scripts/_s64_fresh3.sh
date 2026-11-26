#!/bin/bash
A=/mnt/c/ios26/s64-fresh2.bin
B=/mnt/c/ios26/s64-fresh3.bin
echo "=== md5 对比 ==="
md5sum "$A" "$B"
echo
echo "=== 背光 / 显示 / framebuffer ==="
grep -aiE "backlight|brightness|nits|framebuffer|IOFB|display|surface|swap|flip|fbtrace|vblank|IOMobileFramebuffer|dc=|dcs|dim" "$B" | grep -viE "cmdline|DisplayLink|dispatch" | tail -50
echo
echo "=== 最后 40 行 ==="
tail -40 "$B"
echo
echo "=== WindowServer / launchd 关键服务 ==="
for k in "WindowServer" "StartWindowServer" "backboardd" "lsd" "cfprefsd" "configd" "securityd" "SpringBoard" "xpcproxy"; do echo -n "$k="; grep -aoF "$k" "$B" | wc -l; done
