#!/bash
L=/mnt/c/ios26/s98-live.bin
echo "===== A) thread_dump 全部 tl: 行（前 60） ====="
strings -n 6 "$L" | grep -E "tl:" | head -60
echo
echo "===== B) 含 SpringBoard/backboardd 的 tl 行 ====="
strings -n 6 "$L" | grep -E "tl:.*(SpringBoard|backboardd|launchd)" | head -20
echo
echo "===== C) thread_dump 原始行（td pid 之后 40 行文本） ====="
strings -n 4 "$L" | grep -n -A0 "td pid" | head -20
echo
echo "===== DONE ====="
