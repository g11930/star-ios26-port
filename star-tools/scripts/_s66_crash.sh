#!/bin/bash
F=/mnt/c/ios26/s66-log-crash.bin
echo "=== size ==="
wc -c "$F"
echo
echo "=== starcat 全部输出 ==="
grep -a "starcat" "$F" | head -30
echo
echo "=== 崩溃报告关键字段（.ips 内容） ==="
grep -aiE "Exception Type|Exception Subtype|Termination Reason|Terminating Process|Triggered by Thread|Crash Reporter Key|Process:|Path:|Identifier:|Version:|Code Type:|Parent Process|Incident Identifier|Report Version" "$F" | head -50
echo
echo "=== logd .ips 崩溃栈符号（frame/地址） ==="
grep -aiE "logd\[|fsync|__builtin_trap|abort|SIGTRAP|EXC_|0x[0-9a-f]+ +[0-9]+ +" "$F" | grep -viE "cmdline|EXECDBG|trace:" | tail -60
