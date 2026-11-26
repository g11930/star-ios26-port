#!/bin/bash
F=/mnt/c/ios26/s67-log1.bin
echo "=== 1. 所有 P28EXIT 的 pid 顺序（看 logd 崩溃何时停止） ==="
grep -an "P28EXIT: pid .* logd" "$F" | head -20
echo
echo "=== 2. logd 崩溃与关键进程启动的相对位置（行号） ==="
for pat in "loading /usr/libexec/logd" "loading /System/Library/CoreServices/SpringBoard" "loading /usr/libexec/backboardd" "Early boot complete" "starcat: waiting" "StarMsgProbe: pass 1"; do
  echo -n "$pat : "; grep -an "$pat" "$F" | head -1 | cut -d: -f1
done
echo
echo "=== 3. 最后 20 分钟内是否还有新的 logd spawn（崩溃是否持续） ==="
echo -n "logd loading total = "; grep -ac "EXECDBG: loading /usr/libexec/logd" "$F"
echo -n "logd xstat5 total  = "; grep -ac "logd xstat 5" "$F"
echo
echo "=== 4. 对照 s66（修复前）==="
G=/mnt/c/ios26/s66-log-crash.bin
echo -n "s66 logd loading = "; grep -ac "EXECDBG: loading /usr/libexec/logd" "$G"
echo -n "s66 logd xstat5  = "; grep -ac "logd xstat 5" "$G"
