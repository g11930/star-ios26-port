#!/bash
L=/mnt/c/ios26/s113-live.bin
strings -n 6 "$L" > /tmp/s113.txt
echo "===== s113 中 pid39 的 [Common] ====="
grep -E "backboardd\[39:.*\[Common\]" /tmp/s113.txt | cut -c1-140 | head -20
echo "===== s113 中 pid145/156 的 [Common] ====="
grep -E "backboardd\[(145|156):.*\[Common\]" /tmp/s113.txt | cut -c1-140 | head -24
echo "===== s113 中 pid39 是否有 exit/kill ====="
grep -E "backboardd\>:39|backboardd>:39|pid 39|backboardd\[39" /tmp/s113.txt | grep -iE "exit|kill|terminat|crash" | head -5
echo "===== DONE ====="
</bash>
