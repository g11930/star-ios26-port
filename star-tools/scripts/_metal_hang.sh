#!/bin/bash
F=/mnt/c/ios26/s49-staged.bin
echo "=== size ==="
wc -c "$F"
echo
echo "=== metal_dev / MTLCreateSystemDefaultDevice 相关 ==="
grep -aiE "metal_dev|MTLCreateSystemDefaultDevice|IOAccelerator|metal=1|metal_native" "$F" | grep -viE "cmdline|boot-args" | head -30
echo
echo "=== IOAccelerator / GPU service 卡住线索 ==="
grep -aiE "IOAccelerator|IOService.*wait|service.*match|GPU|gfx|adreno|MMU|fault|timeout|mach_msg|send-phase|IPC_MQUEUE" "$F" | grep -viE "cmdline|boot-args|image |\+image" | head -40
echo
echo "=== 进程/崩溃状态 ==="
grep -aiE "crash|SIGTRAP|abort|stuck|hang|deadlock|watchdog" "$F" | grep -viE "panic_on_crash|CrashReporter|cmdline" | head -20
echo
echo "=== 最后 40 行 ==="
tail -40 "$F"
