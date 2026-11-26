#!/bin/bash
# 抓取当前 s205 运行中的 staged 日志（内核 alive 先 oem log 刷新，再 get_staged）
F=/mnt/d/桌面/adb-fastboot/fastboot.exe
S=xnuloader
OUT=/mnt/c/ios26
echo "== fastboot devices =="
timeout 8 "$F" devices 2>&1 | tr -d '\r'
echo "== oem log (refresh staged) =="
timeout 30 "$F" -s $S oem log 2>&1 | tr -d '\r' | tail -2
sleep 1
echo "== get_staged =="
timeout 90 "$F" -s $S get_staged C:/ios26/s205-cur.bin 2>&1 | tr -d '\r' | tail -2
ls -la /mnt/c/ios26/s205-cur.bin
