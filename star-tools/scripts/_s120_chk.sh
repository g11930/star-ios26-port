#!/bash
L=/mnt/c/ios26/s120-live.bin
strings -n 6 "$L" > /tmp/s120.txt
echo "===== 1) 计数 ====="
for pat in "annibale lib loaded" "starting /usr/libexec/backboardd" "start HID system" "start window server" "Initializing CAWindowServer" "window server hooks" "P28FAULT" "Removing all cached process handles" "Received handshake request from"; do
  echo -n "  $pat = "; grep -c "$pat" /tmp/s120.txt
done
echo
echo "===== 2) backboardd 实例与启动时刻 ====="
grep -E "backboardd\[[0-9]+:[0-9]+\] \[Common\] (starting|start |       )" /tmp/s120.txt | cut -c20-150 | head -20
echo
echo "===== 3) handshake 应答 pid ====="
grep -i "Received handshake request from" /tmp/s120.txt | cut -c33-140
echo
echo "===== 4) WindowServer / CAWindowServer ====="
grep -iE "WindowServer|CAWindowServer" /tmp/s120.txt | cut -c20-150 | head -10
echo
echo "===== 5) disp0 / selector / swap ====="
grep -iE "disp0|selector|swap" /tmp/s120.txt | cut -c1-140 | head -12
echo
echo "===== 6) frame ====="
python3 -c "
d=open('/mnt/c/ios26/s120-frame.raw','rb').read()
print('len',len(d),'nonzero',sum(1 for b in d if b))
"
echo "===== DONE ====="
</bash>
