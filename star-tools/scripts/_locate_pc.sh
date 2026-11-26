#!/bin/bash
F=/mnt/c/ios26/s67-log1.bin
echo "=== 1. dyld shared region / slide 线索（用于符号化 PC） ==="
grep -aiE "unnest of range|shared region|dyld.*map|slide|0x1[0-9a-f]{8}->0x1" "$F" | head -20
echo
echo "=== 2. backboardd 卡住的 PC/LR 全序列（看是否稳定） ==="
grep -aoE "backboardd.*pc=0x[0-9a-f]+ lr=0x[0-9a-f]+" "$F" | head -5
grep -aoE "WAIT pc=0x[0-9a-f]+ lr=0x[0-9a-f]+" "$F" | sort | uniq -c | sort -rn | head -20
echo
echo "=== 3. launchd 全部线程（pass1 里 launchd 段） ==="
grep -a "StarMsgProbe: pass 1" "$F" | tr 'S' '\n' | grep -A40 "=== launchd" | head -45
echo
echo "=== 4. 用户态插桩给的 backboardd 调用栈（wait N 行） ==="
grep -a "backboardd wait" "$F" | head -8
echo
echo "=== 5. SpringBoard 用户态 wait 栈 ==="
grep -a "SpringBoard wait" "$F" | head -8
