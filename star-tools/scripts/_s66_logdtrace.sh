#!/bin/bash
F=/mnt/c/ios26/s66-log-crash.bin
echo "=== logdtrace 输出总量 ==="
grep -ac "logdtrace" "$F"
echo
echo "=== logdtrace 最后 80 行（崩溃前后） ==="
grep -a "logdtrace" "$F" | tail -80
echo
echo "=== say <logd pid> 的所有 trace（找 pc/retaddr/close/fsync 关键字） ==="
grep -aE "logdtrace" "$F" | grep -aiE "fsync|close|pc=|retaddr|SIGTRAP|trap|abort|assert|write|error|fail|stat|open" | tail -60
