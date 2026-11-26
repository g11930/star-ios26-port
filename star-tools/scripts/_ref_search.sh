#!/bin/bash
D=/root/ref/dada/kernel/xnu-12377.121.6-dada.patch
W=/root/ref/warsaw/xnu/patches

echo "########## A. dada.patch 里和 IPC/mach_msg/turnstile/bootstrap 相关的行 ##########"
grep -niE "mach_msg2|mach_msg_overwrite|MACH_SEND_SYNC|turnstile|special reply|ipc_mqueue|bootstrap port|persistent port|SEND_SYNC|rcv_sync|sync sender" "$D" 2>/dev/null | head -60

echo
echo "########## B. warsaw 补丁里同样关键词 ##########"
grep -rniE "mach_msg2|mach_msg_overwrite|MACH_SEND_SYNC|turnstile|special reply|ipc_mqueue|bootstrap port|SEND_SYNC|sync sender" "$W" 2>/dev/null | head -60

echo
echo "########## C. 参考文档里关于启动卡住 / 桌面 / backboardd 的线索 ##########"
grep -rniE "backboardd|98%|desktop|SpringBoard.*stuck|hang|deadlock|mach_msg|launchd" /root/ref/warsaw/docs /root/ref/dada 2>/dev/null | grep -viE "\.patch:|Binary file" | head -50

echo
echo "########## D. dada 里 kern_credential / ubc_subr / exception 的注释 ##########"
for f in kern_credential.c ubc_subr.c; do
  echo "--- $f ---"
  awk -v fn="bsd/kern/$f" 'index($0,"diff --git a/"fn){p=1} p{print} p && /^diff --git/ && !index($0,fn){exit}' "$D" 2>/dev/null | grep -iE "PAC|ptrauth|guard|sign|auth|panic|null|crash|comment|\/\*|^[+-].*(check|return|if)" | head -25
done
