#!/bash
L=/mnt/c/ios26/s118-live.bin
strings -n 6 "$L" > /tmp/s118.txt
echo -n "文件行数: "; wc -l < /tmp/s118.txt
echo -n "backboardd 提及: "; grep -c "backboardd" /tmp/s118.txt
echo "--- 最后 15 行:"
tail -15 /tmp/s118.txt | cut -c1-140
echo
echo "--- 前 12 行:"
head -12 /tmp/s118.txt | cut -c1-140
echo
echo "--- 进程启动痕迹（EXECDBG loading）:"
grep -c "EXECDBG: loading" /tmp/s118.txt
grep "EXECDBG: loading" /tmp/s118.txt | tail -8 | cut -c1-120
echo "===== DONE ====="
</bash>
