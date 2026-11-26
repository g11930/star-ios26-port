#!/bin/bash
F=/mnt/c/ios26/s64-fresh6.bin
echo "=== persistent services / mach port 相关（本轮真实） ==="
grep -aiE "persistent|mach port|bootstrap|look.?up|KERN_INVALID|kr=15|no mach" "$F" | grep -viE "cmdline|boot-args" | head -40
echo
echo "=== launchd Notice/Error 级别日志 ==="
grep -a "com.apple.xpc.launchd" "$F" | grep -iE "Notice|Error|Warning|error|fail|could not|unable" | head -40
echo
echo "=== 是否有 XPC/bootstrap 报错 ==="
grep -aiE "xpc|bootstrap|service.*(fail|error|missing|not found)|could not launch|unable to|failed to" "$F" | grep -viE "cmdline|boot-args|libxpc|EXECDBG" | head -40
