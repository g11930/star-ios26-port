#!/bin/bash
# s205 重刷 + 长等待 + 抓取验证 fb_diff 移除效果。
# 设备已在 fastboot：直接 fastboot boot s205-boot.img，等 8 分钟让统计窗口
# （s200 实测约 5.7 分钟打印 "frames in ..."）走完，再连抓两份 staged。
set -u
F=/mnt/d/桌面/adb-fastboot/fastboot.exe
# 注意：get_staged 的输出路径是传给 Windows fastboot.exe 的，必须用 Windows 路径
OUT=C:/ios26
IMG=C:/ios26/s205-boot.img

echo "=== [0] where are we ==="
timeout 8 "$F" devices 2>&1 | tr -d '\r'

echo "=== [1] wait for fastboot ==="
ok=0
for i in $(seq 1 40); do
  p=$(timeout 8 "$F" getvar product 2>&1 | tr -d '\r' | grep -m1 'product:' || true)
  if [ -n "$p" ]; then echo "  bootloader up: $p"; ok=1; break; fi
  sleep 2
done
if [ "$ok" != "1" ]; then echo "NO BOOTLOADER"; exit 1; fi

echo "=== [2] boot s205 ==="
timeout 200 "$F" boot "$IMG" 2>&1 | tr -d '\r' | tail -5

echo "=== [3] wait for loader (xnuloader) ==="
for i in $(seq 1 45); do
  d=$(timeout 8 "$F" devices 2>&1 | tr -d '\r' | grep -c 'xnuloader' || true)
  if [ "$d" != "0" ]; then echo "  loader up after $((i*2))s"; break; fi
  sleep 2
done
timeout 8 "$F" devices 2>&1 | tr -d '\r'

echo "=== [4] wait 8 min for stats window ==="
for i in $(seq 1 24); do
  sleep 20
  echo "  ... $((i*20))s"
done

echo "=== [5] capture #1 ==="
timeout 20 "$F" -s xnuloader oem log >/dev/null 2>&1
rm -f "$OUT/s205b-1.bin"
timeout 60 "$F" -s xnuloader get_staged "$OUT/s205b-1.bin" 2>&1 | tr -d '\r' | tail -2
sz1=$(stat -c%s "$OUT/s205b-1.bin" 2>/dev/null || echo 0)
echo "  size1=$sz1"

echo "=== [6] wait 2 min, capture #2 ==="
sleep 120
timeout 20 "$F" -s xnuloader oem log >/dev/null 2>&1
rm -f "$OUT/s205b-2.bin"
timeout 60 "$F" -s xnuloader get_staged "$OUT/s205b-2.bin" 2>&1 | tr -d '\r' | tail -2
sz2=$(stat -c%s "$OUT/s205b-2.bin" 2>/dev/null || echo 0)
echo "  size2=$sz2"

echo "=== [7] quick analysis ==="
python3 - <<'PY'
import re, glob
for p in sorted(glob.glob('/mnt/c/ios26/s205b-*.bin')):
    try:
        d = open(p, 'rb').read().decode('utf-8', 'replace').replace('\0', '')
    except Exception as e:
        print(p, 'ERR', e); continue
    ts = re.findall(r'2025-\d\d-\d\d \d\d:\d\d:\d\d', d)
    last = ts[-1] if ts else '-'
    frames = re.findall(r'MiniIOMobileFramebuffer: (\d+) frames in (\d+) ms \((\d+) a second\), (\d+) us each in the driver[^;]*; (\d+) us waiting for the GPU', d)
    diff = re.findall(r'(\d+) pixels of the panel changed a frame', d)
    p34 = re.findall(r'P34: panel swap (\d+)[^\n]*', d)
    tlv = re.findall(r'tl: v (\d+) ready \d+ shown \d+ done \d+', d)
    print('== %s  last_ts=%s' % (p, last))
    print('   frames_stats=%s' % (frames[-1] if frames else 'NONE'))
    print('   diff_pixels=%s' % (diff[-1] if diff else 'NONE'))
    print('   p34=%s' % (p34[-1][:80] if p34 else 'NONE'))
    print('   tlv=%s' % (tlv[-1] if tlv else 'NONE'))
PY
echo "=== done ==="
