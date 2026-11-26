#!/bash
L=/mnt/c/ios26/s101-live.bin
echo "===== 全部 IOSvcQuery ====="
strings -n 8 "$L" | grep "IOSvcQuery" | sed -n '1,80p'
echo
echo "===== 其中 backboardd / SpringBoard 的查询 ====="
strings -n 8 "$L" | grep "IOSvcQuery" | grep -E "backboardd|SpringBoard|runningboard|launchd" | head -30
echo
echo "===== 计数 ====="
echo -n "queries: "; strings "$L" | grep -c "IOSvcQuery"
echo -n "s100 open: "; strings "$L" | grep -c "s100 open asked"
echo "===== DONE ====="
