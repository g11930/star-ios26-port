#!/bash
L=/mnt/c/ios26/s123-live.bin
strings -n 6 "$L" > /tmp/s123.txt
echo "===== 1) 计数 ====="
for pat in "delayexec" "annibale lib loaded" "start HID system" "start window server" "Initializing CAWindowServer" "window server hooks" "P28FAULT" "Received handshake request from"; do
  echo -n "  $pat = "; grep -c "$pat" /tmp/s123.txt
done
echo
echo "===== 2) backboardd 实例与关键节点 ====="
grep -E "delayexec|backboardd\[" /tmp/s123.txt | grep -E "delayexec: sleeping|\[Common\] starting|Removing all cached|Sending handshake|start HID|start GS|start window|Initializing CAWindowServer" | cut -c1-150 | head -14
echo
echo "===== 3) handshake 应答（全部）====="
grep -i "Received handshake request from" /tmp/s123.txt | cut -c20-140
echo
echo "===== 4) WindowServer/CA/disp0 ====="
grep -iE "WindowServer|CAWindowServer|disp0" /tmp/s123.txt | cut -c20-150 | head -10
echo
echo "===== 5) frame ====="
python3 -c "
d=open('/mnt/c/ios26/s123-frame.raw','rb').read()
print('len',len(d),'nonzero',sum(1 for b in d if b))
"
echo "===== DONE ====="
</bash>
