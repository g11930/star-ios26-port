#!/bash
F=/mnt/c/ios26/s97-live.bin
G=/mnt/c/ios26/s96-live.bin
echo "===== 1) entitlement / container 计数对比 ====="
for p in "SecTaskLoadEntitlements failed error=22" "NOT_CODESIGNED" "cs_flags="; do
  a=$(strings "$F" | grep -c "$p"); b=$(strings "$G" | grep -c "$p")
  echo "  $p : s97=$a  s96=$b"
done
echo
echo "===== 2) SpringBoard / backboardd 存活与重启 ====="
echo "--- SpringBoard pids seen:"
strings "$F" | grep -oE "SpringBoard\[[0-9]+" | sort -u | head -10
echo "--- backboardd pids seen:"
strings "$F" | grep -oE "backboardd\[[0-9]+" | sort -u | head -10
echo "--- crash/exception:"
strings "$F" | grep -Ei "crash|exited abnormally|SIGTRAP|SIGKILL|abort" | head -10
echo
echo "===== 3) 启动里程碑 ====="
strings "$F" | grep -Ei "handshake request|runningboard|FBSystemShell|frontboard|iconservices|scene|UIKit|SpringBoard.*launch|SystemShell|activation" | head -20
echo
echo "===== 4) 最后 40 条带时间戳的日志 ====="
strings -n 10 "$F" | grep -E "^20[0-9]{2}-" | tail -40
echo
echo "===== DONE ====="
