#!/bin/bash
F=/mnt/c/ios26/s67-log1.bin
echo "=== size ==="
wc -c "$F"
echo
echo "########## 判据1: logd 崩溃次数（xstat 5） ##########"
echo -n "s67 logd xstat5 = "; grep -ac "logd xstat 5" "$F"
echo -n "s67 logd loading = "; grep -ac "EXECDBG: loading /usr/libexec/logd" "$F"
echo "--- 明细 ---"
grep -aoE "P28EXIT: pid [0-9]+ logd xstat [0-9]+" "$F" | head -20
echo
echo "########## 判据2: backboardd SEND / turnstile 目标 ##########"
grep -aoE "TURNSTILE-PORT type=[A-Za-z0-9_]+|peer=[A-Za-z]+\([0-9]+\) type=IOT_SERVICE_PORT|peer=launchd\([0-9]+\)" "$F" | sort | uniq -c
echo
echo "########## 判据3: 启动进度 / 新服务 ##########"
for k in "Early boot complete" "WindowServer" "StartWindowServer" "SpringBoard" "backboardd" "cfprefsd" "configd" "securityd" "lsd"; do echo -n "$k="; grep -ac "$k" "$F"; done
echo
echo "########## 判据4: logd 是否活着（最后 trace） ##########"
grep -a "logdtrace" "$F" | tail -8
echo
echo "########## 判据5: 崩溃/异常 ##########"
grep -aiE "SIGTRAP|EXC_|panic|Kernel data abort|crash" "$F" | grep -viE "cmdline|boot-args|panic_on_crash|CrashReporter|crash_mover" | head -15
echo
echo "########## 最后 25 行 ##########"
tail -25 "$F"
