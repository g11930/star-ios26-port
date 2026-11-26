#!/bin/bash
echo "=== s64/s65 parts 里的 ramdisk 来自哪轮 ==="
for t in s64 s65; do
  echo "--- $t parts ---"
  ls -la /root/star26/$t/parts/ 2>/dev/null | grep -iE "ramdisk|rdimage"
done
echo
echo "=== 找最近有完整 root tree 的轮（有 etc/rc.jobs） ==="
for t in $(ls -d /root/star26/s* 2>/dev/null | sort -V | tail -30); do
  if [ -f "$t/work/root/etc/rc.jobs" ]; then
    echo "$t : $(stat -c %y "$t/work/root/etc/rc.jobs" | cut -d. -f1)"
  fi
done
echo
echo "=== 当前 s64 ramdisk 大小/sha ==="
ls -la /root/star26/s64/parts/ramdisk 2>/dev/null
md5sum /root/star26/s64/parts/ramdisk 2>/dev/null
