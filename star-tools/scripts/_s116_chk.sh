#!/bash
L=/mnt/c/ios26/s116-live.bin
strings -n 6 "$L" > /tmp/s116.txt
echo "===== 1) 关键计数 ====="
for pat in "start window server" "Initializing CAWindowServer" "P28FAULT" "annibale lib loaded" "Unable to query displays"; do
  echo -n "  $pat: "; grep -c "$pat" /tmp/s116.txt
done
echo -n "  IOSvcOpen: "; grep -c "IOSvcOpen" /tmp/s116.txt
echo -n "  selector: "; grep -c "MiniIOMobileFramebuffer: .* selector" /tmp/s116.txt
echo
echo "===== 2) backboardd [Common] ====="
grep -E "\[Common\]" /tmp/s116.txt | grep -E "start|ready" | cut -c1-130 | head -24
echo
echo "===== 3) 主线程最后动作 ====="
grep -E "backboardd\[39:277\]" /tmp/s116.txt | cut -c1-145 | tail -14
echo
echo "===== 4) 全局最后 10 行 ====="
tail -10 /tmp/s116.txt | cut -c1-140
echo
echo "===== 5) frame ====="
python3 -c "
d=open('/mnt/c/ios26/s116-frame.raw','rb').read()
print('len',len(d),'nonzero',sum(1 for b in d if b))
"
echo "===== DONE ====="
</bash>
