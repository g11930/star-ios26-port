#!/bin/bash
# s198 采样：每 25 秒 oem log + get_staged 一次，共 20 轮（约 9 分钟）
# 目的：抓 first_frame 之后的 tl: s / tl: v / tl: l —— 看 swap 提交是否持续
F=/mnt/d/桌面/adb-fastboot/fastboot.exe
for i in $(seq 1 20); do
  timeout 20 "$F" -s xnuloader oem log >/dev/null 2>&1
  rm -f "/mnt/c/ios26/s198mon-$i.bin"
  timeout 60 "$F" -s xnuloader get_staged "C:/ios26/s198mon-$i.bin" >/dev/null 2>&1
  size=$(stat -c%s "/mnt/c/ios26/s198mon-$i.bin" 2>/dev/null || echo 0)
  # 摘要：milestone / tl: s 计数 / SpringBoard
  if [ "$size" != "0" ]; then
    s=$(grep -c 'tl: s ' "/mnt/c/ios26/s198mon-$i.bin" 2>/dev/null || echo 0)
    v=$(grep -c 'tl: v ' "/mnt/c/ios26/s198mon-$i.bin" 2>/dev/null || echo 0)
    l=$(grep -c 'tl: l ' "/mnt/c/ios26/s198mon-$i.bin" 2>/dev/null || echo 0)
    m=$(grep -c 'first_frame' "/mnt/c/ios26/s198mon-$i.bin" 2>/dev/null || echo 0)
    f=$(grep -c 'frames in ' "/mnt/c/ios26/s198mon-$i.bin" 2>/dev/null || echo 0)
  else
    s=0; v=0; l=0; m=0; f=0
  fi
  echo "[$i] $(date +%T) size=$size tl_s=$s tl_v=$v tl_l=$l first_frame=$m stats=$f"
  sleep 25
done
echo "=== sampling done ==="
