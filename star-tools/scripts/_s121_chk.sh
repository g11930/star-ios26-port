#!/bash
L=/mnt/c/ios26/s121-live.bin
strings -n 6 "$L" > /tmp/s121.txt
echo "===== 1) 计数 ====="
for pat in "annibale lib loaded" "start HID system" "start window server" "Initializing CAWindowServer" "window server hooks" "P28FAULT" "Received handshake request from" "termination reported"; do
  echo -n "  $pat = "; grep -c "$pat" /tmp/s121.txt
done
echo
echo "===== 2) triald / RB 启动时序 ====="
grep -E "EXECDBG: loading /usr/libexec/triald|triald\[[0-9]+:[0-9]+\] \[server\]|Initializing TRIClient|Battlecruiser operational" /tmp/s121.txt | cut -c1-150 | head -10
echo
echo "===== 3) handshake 应答 ====="
grep -i "Received handshake request from" /tmp/s121.txt | cut -c33-130
echo
echo "===== 4) backboardd 关键节点 ====="
grep -E "backboardd\[" /tmp/s121.txt | grep -E "Removing all cached|Sending handshake|start HID|start GS|start window|Initializing CAWindowServer|\[Common\] start" | cut -c20-150 | head -16
echo
echo "===== 5) WindowServer / CA ====="
grep -iE "WindowServer|CAWindowServer|Unable to query displays" /tmp/s121.txt | cut -c20-150 | head -8
echo
echo "===== 6) frame ====="
python3 -c "
d=open('/mnt/c/ios26/s121-frame.raw','rb').read()
print('len',len(d),'nonzero',sum(1 for b in d if b))
"
echo "===== DONE ====="
</bash>
