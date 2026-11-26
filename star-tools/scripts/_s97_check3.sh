#!/bash
L=/mnt/c/ios26/s97-live2.bin
echo "===== A) 时间范围 ====="
strings -n 8 "$L" | grep -oE "^2025-[0-9-]+ [0-9:.+]+" | sed -n '1p;$p'
echo
echo "===== B) 关键计数 ====="
for p in "error=22" "NOT_CODESIGNED" "WindowServer" "Scene" "lock screen" "first_frame"; do
  echo -n "  $p: "; strings "$L" | grep -ci "$p"
done
echo
echo "===== C) 新增里程碑（最后 60 条 SpringBoard/frontboard/scene） ====="
strings -n 8 "$L" | grep -Ei "SpringBoard\[33|frontboard|scene|workspace|lock" | tail -30
echo
echo "===== D) 末尾 25 条日志 ====="
strings -n 10 "$L" | grep -E "^20[0-9]{2}-" | tail -25
echo
echo "===== DONE ====="
