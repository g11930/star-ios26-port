#!/bin/bash
echo "=== 各轮 root.apfs 与当前 ramdisk 的 md5 ==="
md5sum /root/star26/s64/parts/ramdisk 2>/dev/null | sed 's#.*/parts/#CURRENT s64 ramdisk: #'
for t in s58 s57 s56 s55 s54; do
  f=/root/star26/$t/root.apfs
  [ -f "$f" ] && md5sum "$f" | sed "s#$f#$t/root.apfs#"
done
echo
echo "=== s58 rc.jobs 内容 ==="
cat /root/star26/s58/work/root/etc/rc.jobs 2>/dev/null
echo
echo "=== s58 ramdisk 里有没有 starcat ==="
ls -la /root/star26/s58/work/root/annibale/bin/starcat 2>/dev/null || echo "no starcat in s58 root"
echo
echo "=== 当前 s64 ramdisk 里有没有 starcat（用 mkapfs 列表或直接 strings） ==="
grep -ao "starcat" /root/star26/s64/parts/ramdisk 2>/dev/null | head -3 || echo "no starcat string in ramdisk"
