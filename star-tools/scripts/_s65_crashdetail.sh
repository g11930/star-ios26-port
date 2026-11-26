#!/bin/bash
F=/mnt/c/ios26/s65-log1.bin
echo "=== 1. 崩溃异常类型/终止原因（logdump 里可能残留） ==="
grep -aiE "Exception Type|Termination Reason|EXC_BAD|EXC_CRASH|SIGTRAP|SIGABRT|SIGSEGV|abort\(\)|assert|fatal|Terminated|crashed|Jetsam|watchdog" "$F" | grep -viE "cmdline|boot-args|panic_on_crash|CrashReporter|crash_mover|ReportCrash|crashreportcopy" | head -40
echo
echo "=== 2. backboardd 崩溃前的最后用户态 trace（beat/wait 之外的） ==="
grep -aE "say 39" "$F" | grep -viE "beat |wait [0-9]|ctor|heartbeat|SIGPROF|image|\+image|interposing" | head -30
echo
echo "=== 3. crash report 落盘位置线索 ==="
grep -aiE "CrashReporter|\.ips|Library/Logs|crash_files" "$F" | head -20
echo
echo "=== 4. launchd 与 service port 交互（check-in / spawn 决策） ==="
grep -aiE "launchd" "$F" | grep -aiE "service|spawn|check|lookup|xpcproxy|ondemand|bootstrap|port" | grep -viE "cmdline|boot-args|no mach port for persistent" | tail -30
echo
echo "=== 5. 全部非空 exit / crash 信号 ==="
grep -aE "P28EXIT|xstat|EXC_|signal [0-9]|killed by" "$F" | grep -iE "backboard|signal|EXC_|killed" | head -30
