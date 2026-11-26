#!/bin/bash
# s214 = s212 全部组件逐字节不变，唯一改动：cmdline pac_patch=2 -> pac_patch=1
# 目的：验证"RETAA 页改写"是否为 s212 自发解锁不触发的根因（掩码类别实验 Step 1）
set -e
S212=/root/star26/baseline/s212parts
S214=/root/star26/baseline/s214parts
MK=/root/star26/hackios-xnu-kernel/xnuloader/mkpayload.py
RESEAL=/root/star26/hackios-xnu-kernel/tools/reseal-loader-img.py
P2=/root/star26/p2/p2-boot.img
X=/mnt/d/桌面/star26-deps/scripts/xnup_info.py

echo "=== [0] preflight: s212 kernel md5 ==="
[ "$(md5sum "$S212/kernel"|cut -d' ' -f1)" = 0a3b5eda59bad5e7bce73640a11fe4ed ] || { echo "s212 KERNEL MD5 MISMATCH"; exit 1; }
echo "  OK 0a3b5eda59bad5e7bce73640a11fe4ed"

echo "=== [1] repro check: rebuild s212 payload from s212 parts, compare md5 ==="
REPRO=/tmp/s212-repro-payload.bin
python3 "$MK" -o "$REPRO" \
  loader.efi="$S212/loader.efi" kernel="$S212/kernel" ramdisk="$S212/ramdisk" \
  rdimage="$S212/rdimage" \
  --cmdline "$(tr -d '\0' < "$S212/cmdline")" --memsize "$(tr -d '\0' < "$S212/memsize")" \
  --identity "$(tr -d '\0' < "$S212/identity")" >/dev/null 2>&1
A=$(md5sum "$S212/s212-payload.bin"|cut -d' ' -f1)
B=$(md5sum "$REPRO"|cut -d' ' -f1)
echo "  orig=$A"
echo "  repro=$B"
[ "$A" = "$B" ] || { echo "REPRO MISMATCH -- toolchain not reproducible, ABORT"; exit 1; }
echo "  REPRO OK"

echo "=== [2] build s214parts: copy all s212 components ==="
mkdir -p "$S214"
for name in loader.efi ramdisk rdimage memsize identity kernel; do
  cp -f "$S212/$name" "$S214/$name"
done

echo "=== [3] cmdline: pac_patch=2 -> 1 (single byte) ==="
python3 - "$S212/cmdline" "$S214/cmdline" <<'PY'
import sys
src, dst = sys.argv[1], sys.argv[2]
b = open(src, 'rb').read()
assert b.count(b'pac_patch=2') == 1, 'pac_patch=2 not exactly once'
assert b.count(b'pac_patch=1') == 0, 'pac_patch=1 already present'
n = b.replace(b'pac_patch=2', b'pac_patch=1')
assert len(n) == len(b) == 540
open(dst, 'wb').write(n)
print('  cmdline 540B, pac_patch=2 -> 1, len unchanged')
print('  tail:', n[-40:].decode('ascii','replace'))
PY

echo "=== [4] guard: non-cmdline components byte-identical to s212 ==="
for name in loader.efi ramdisk rdimage memsize identity kernel; do
  A=$(md5sum "$S212/$name"|cut -d' ' -f1); C=$(md5sum "$S214/$name"|cut -d' ' -f1)
  [ "$A" = "$C" ] || { echo "CHANGED: $name"; exit 1; }
done
echo "  all components identical to s212"

echo "=== [5] pack s214 payload + img ==="
CL=$(tr -d '\0' < "$S214/cmdline")
python3 "$MK" -o "$S214/s214-payload.bin" \
  loader.efi="$S214/loader.efi" kernel="$S214/kernel" ramdisk="$S214/ramdisk" \
  rdimage="$S214/rdimage" --cmdline "$CL" \
  --memsize "$(tr -d '\0' < "$S214/memsize")" --identity "$(tr -d '\0' < "$S214/identity")" 2>&1 | tail -1
python3 "$RESEAL" -o /mnt/c/ios26/s214-boot.img "$P2" "$S214/s214-payload.bin" 2>&1 | tail -1

echo "=== [6] STRICT verify: s214 vs s212 differ in exactly 1 byte ==="
python3 - <<'PY'
a = open('/mnt/c/ios26/s212-boot.img','rb').read()
b = open('/mnt/c/ios26/s214-boot.img','rb').read()
print('  sizes', len(a), len(b))
assert len(a)==len(b), 'SIZE DIFF'
diff = [i for i in range(len(a)) if a[i]!=b[i]]
print('  diff byte count:', len(diff))
assert len(diff)==1, 'DIFF NOT EXACTLY 1 BYTE'
i = diff[0]
print('  diff at offset %d: s212=%r -> s214=%r' % (i, chr(a[i]), chr(b[i])))
assert (a[i],b[i])==(ord('2'),ord('1')), 'DIFF NOT pac_patch 2->1'
print('  context:', repr(b[i-20:i+10]))
print('  STRICT VERIFY PASS -- only pac_patch digit changed')
PY

echo "=== [7] xnup_info cmdline diff ==="
diff <(python3 "$X" /mnt/c/ios26/s212-boot.img 2>/dev/null | grep 'cmdline:') \
     <(python3 "$X" /mnt/c/ios26/s214-boot.img 2>/dev/null | grep 'cmdline:') || true
echo "=== [8] final hash ==="
sha256sum /mnt/c/ios26/s214-boot.img
ls -la /mnt/c/ios26/s214-boot.img
