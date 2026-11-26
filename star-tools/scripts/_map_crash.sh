#!/bash
set -e
SRC=/root/dsc26/System/Library/Caches/com.apple.dyld
DST=/root/dsc26-ln
rm -rf $DST; mkdir -p $DST
cd $SRC
for f in dyld_shared_cache_arm64e*; do
  [ -s "$f" ] || continue
  case "$f" in *.dylddata|*decmpfs*) continue;; esac
  ln -sf "$SRC/$f" "$DST/$f"
done
ls $DST | wc -l
cd /root/star26/hackios-xnu-kernel/tools/dsc
echo "===== 地址映射 ====="
python3 dsc.py --cache $DST map 0x1865bf408 0x1841a7e18 0x1865b0000 2>&1 | head -10
echo "===== 崩溃点反汇编 ====="
python3 dsc.py --cache $DST disasm 0x1865bf3d0 --count 20 2>&1 | head -30
echo "===== DONE ====="
</bash>
