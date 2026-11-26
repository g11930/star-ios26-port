#!/bash
L=/mnt/c/ios26/s122-live.bin
strings -n 6 "$L" > /tmp/s122.txt
echo "===== 1) 计数 ====="
for pat in "trialwake" "annibale lib loaded" "start HID system" "start window server" "Initializing CAWindowServer" "window server hooks" "P28FAULT" "Received handshake request from"; do
  echo -n "  $pat = "; grep -c "$pat" /tmp/s122.txt
done
echo
echo "===== 2) trialwake 输出 ====="
grep "trialwake" /tmp/s122.txt | cut -c1-150 | head -6
echo
echo "===== 3) 关键时序（triald / RB / backboardd）====="
grep -E "triald\[[0-9]+:[0-9]+\] \[server\] New connection|Initializing TRIClient|Received handshake request from|backboardd\[" /tmp/s122.txt | grep -E "Initializing TRIClient|Received handshake|triald\[.*New connection|\[Common\] starting|start HID|start GS|start window|Initializing CAWindowServer" | cut -c20-140 | head -22
echo
echo "===== 4) frame ====="
python3 -c "
d=open('/mnt/c/ios26/s122-frame.raw','rb').read()
print('len',len(d),'nonzero',sum(1 for b in d if b))
"
echo "===== DONE ====="
</bash>
