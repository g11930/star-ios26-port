#!/bash
L=/mnt/c/ios26/s100-live.bin
echo "===== backboardd 主线程(284/其它低 tid) 启动序列 ====="
strings -n 6 "$L" | grep -E "backboardd\[39:(284|340|4[0-9][0-9])\]" | grep -vE "connection|BKIOHID" | sed -n '1,60p'
echo
echo "===== 末尾 10 条 backboardd 主线程 ====="
strings -n 6 "$L" | grep -E "backboardd\[39:(284|340)\]" | tail -10
echo "===== DONE ====="
