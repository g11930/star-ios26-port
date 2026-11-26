#!/bin/bash
# s205 = s200 六个组件逐字节不变，唯一变量 = cmdline 去掉 fb_diff=1。
# 依据：驱动自报 685839 us/frame in the driver，fDiff 每帧对面板非缓存内存做 4.6M 次读，
# 且强制单线程绘制。gDiff 默认本就是 0（MiniIOMobileFramebuffer.cpp:147）。
set -e
B=/root/star26/baseline/s205parts
OLD=/root/star26/baseline/s200parts
X=/mnt/d/桌面/star26-deps/scripts/xnup_info.py
mkdir -p "$B"

echo "=== [1] copy s200 components unchanged ==="
for name in loader.efi kernel ramdisk rdimage memsize identity; do
  cp -f "$OLD/$name" "$B/$name"
done

echo "=== [2] guard: all six identical to s200 ==="
for name in loader.efi kernel ramdisk rdimage memsize identity; do
  A=$(md5sum "$OLD/$name" | cut -d' ' -f1)
  C=$(md5sum "$B/$name"  | cut -d' ' -f1)
  [ "$A" = "$C" ] || { echo "COMPONENT CHANGED: $name"; exit 1; }
done
echo "all six identical"

echo "=== [3] cmdline: s200 minus fb_diff=1 ==="
python3 - "$OLD/cmdline" "$B/cmdline" <<'PY'
import sys
raw = open(sys.argv[1], 'rb').read().replace(b'\x00', b'')
cl = raw.decode('utf-8')
tokens = [t for t in cl.split(' ') if t]
if 'fb_diff=1' not in tokens:
    print('FATAL: fb_diff=1 not found in s200 cmdline')
    sys.exit(1)
kept = [t for t in tokens if t != 'fb_diff=1']
out = ' '.join(kept)
open(sys.argv[2], 'wb').write(out.encode('utf-8'))
print('removed: fb_diff=1')
PY
CL=$(cat "$B/cmdline")
LEN=$(printf '%s' "$CL" | wc -c)
echo "cmdline now ${LEN} B (was 528, limit 1024)"
[ "$LEN" -lt 1000 ] || { echo "CMDLINE TOO LONG"; exit 1; }
for a in touch_diag=0 touch_lat=1; do
  case "$CL" in
    *"$a"*) echo "  $a present" ;;
    *) echo "  $a MISSING"; exit 1 ;;
  esac
done
case "$CL" in
  *fb_diff*) echo "  fb_diff STILL PRESENT"; exit 1 ;;
  *) echo "  fb_diff absent (correct: default 0)" ;;
esac

echo "=== [4] repack ==="
python3 /root/star26/hackios-xnu-kernel/xnuloader/mkpayload.py \
  -o "$B/s205-payload.bin" loader.efi="$B/loader.efi" kernel="$B/kernel" ramdisk="$B/ramdisk" \
  rdimage="$B/rdimage" \
  --cmdline "$CL" --memsize "$(tr -d '\0' < "$B/memsize")" \
  --identity "$(tr -d '\0' < "$B/identity")" 2>&1 | tail -1
python3 /root/star26/hackios-xnu-kernel/tools/reseal-loader-img.py \
  -o /mnt/c/ios26/s205-boot.img /root/star26/p2/p2-boot.img "$B/s205-payload.bin" 2>&1 | tail -1

echo "=== [5] single-variable check: only cmdline differs from s200 ==="
echo "--- s205 ---"
python3 "$X" /mnt/c/ios26/s205-boot.img 2>&1 | head -12
echo "--- s200 for comparison ---"
python3 "$X" /mnt/c/ios26/s200-boot.img 2>&1 | head -12
sha256sum /mnt/c/ios26/s205-boot.img
