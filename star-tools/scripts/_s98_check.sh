#!/bash
L=/mnt/c/ios26/s98-live.bin
echo "===== 1) IOAcceleratorES 新诊断 ====="
strings -n 8 "$L" | grep -E "IOAcceleratorES" | head -8
echo
echo "===== 2) StarMsgProbe 概览 ====="
strings -n 8 "$L" | grep -E "StarMsgProbe: (===|pass|done|no target)" | head -25
echo
echo "===== 3) thread_dump 线程行（首 40 条）====="
strings -n 8 "$L" | grep -E "StarMsgProbe:   T#|StarMsgProbe:     " | head -40
echo
echo "===== 4) 计数 ====="
for p in "error=22" "NOT_CODESIGNED" "StarMsgProbe:   T#" "bt" ; do :; done
echo -n "error=22: "; strings "$L" | grep -c "error=22"
echo -n "T# lines: "; strings "$L" | grep -c "StarMsgProbe:   T#"
echo -n "pass lines: "; strings "$L" | grep -c "StarMsgProbe: pass"
echo
echo "===== 5) 末尾时间 ====="
strings -n 8 "$L" | grep -oE "^2025-[0-9-]+ [0-9:.+]+" | sed -n '$p'
echo
echo "===== DONE ====="
