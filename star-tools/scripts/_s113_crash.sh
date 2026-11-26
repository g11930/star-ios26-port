#!/bash
L=/mnt/c/ios26/s113-live.bin
echo "===== 1) backboardd 三次出现的上下文 ====="
strings -n 8 "$L" | grep -nE "backboardd" | grep -viE "annibale|say 39|say 156|say 167" | head -25
echo
echo "===== 2) 进程退出 / 信号 / 崩溃 ====="
strings -n 8 "$L" | grep -iE "Service exited|exited (abnormally|due to)|SIG(KILL|SEGV|BUS|ABRT)|crash|Jetsam|watchdog|0xdead10cc|EXC_" | head -25
echo
echo "===== 3) IOSvcOpen 48 条是谁在开什么 ====="
strings -n 6 "$L" | grep "IOSvcOpen" | head -20
echo
echo "===== 4) s113 里 CAWindowServer / QuartzCore 痕迹 ====="
strings -n 8 "$L" | grep -iE "QuartzCore|CAWindowServer|CADisplay|CoreAnimation" | head -20
echo "===== DONE ====="
</bash>
