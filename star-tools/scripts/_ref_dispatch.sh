#!/bin/bash
D=/root/ref/dada/kernel/xnu-12377.121.6-dada.patch
W=/root/ref/warsaw/xnu/patches

echo "########## A. dada.patch 里 semaphore/dispatch/workloop/pthread/kqueue 相关文件 ##########"
grep "^diff --git" "$D" 2>/dev/null | grep -iE "semaphore|dispatch|workloop|pthread|kqueue|work_interval|turnstile|sched|sync|lock" | sed 's#diff --git a/##; s# b/.*##'

echo
echo "########## B. dada.patch 里这些关键词的实际改动行（带上下文判断） ##########"
grep -niE "semaphore|dispatch_source|workloop|pthread_mutex|kqueue|turnstile.*wait|semaphore_wait|dispatch_queue" "$D" 2>/dev/null | grep -viE "^\s*$" | head -60

echo
echo "########## C. warsaw 补丁里的调度/同步相关 ##########"
grep -rliE "semaphore|dispatch|workloop|pthread|kqueue|turnstile|sched" "$W" 2>/dev/null | head -30

echo
echo "########## D. 参考文档里关于 dispatch/launchd 卡住 ##########"
grep -rniE "dispatch|semaphore|launchd.*hang|launchd.*卡|event loop|事件循环|workloop|spin" /root/ref/warsaw/docs /root/ref/dada/*.md /root/ref/dada/docs 2>/dev/null | grep -viE "\.patch:" | head -40
