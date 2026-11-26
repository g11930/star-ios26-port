#!/bash
L=/mnt/c/ios26/s107-live.bin
echo "===== 全部 IOSvcOpen 行 ====="
strings -n 6 "$L" | grep "IOSvcOpen" | sed 's/^.*IOSvc/IOSvc/' | sort | uniq -c | sort -rn | head -30
echo
echo "===== selector 行 ====="
strings -n 8 "$L" | grep "selector" | sed 's/^.*MiniIOMobileFramebuffer/Mini.../' | sort | uniq -c | head -20
echo
echo "===== notification / swap / present ====="
strings -n 8 "$L" | grep -iE "MiniIOMobileFramebuffer: (notification|swap|present|Started|started)" | head -15
echo
echo "===== WindowServer / Scene ====="
for k in WindowServer first_frame SBScene; do
  printf '%-14s %s\n' "$k" "$(strings "$L" | grep -c -F "$k")"
done
echo
echo "===== 转 PNG ====="
python3 /mnt/d/桌面/star26-deps/scripts/fb2png.py /mnt/c/ios26/s107-frame.raw /mnt/c/ios26/s107-frame.png 2>&1 | tail -3
ls -l /mnt/c/ios26/s107-frame.png 2>/dev/null
echo "===== DONE ====="
