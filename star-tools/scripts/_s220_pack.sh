#!/bin/bash
# s220 = s217 全部组件原样 + cmdline 只把 pac_patch=0 改成 pac_patch=2（类别掩码: 只改 RETAA/RETAB->ret）
# 不重编内核、不碰 s218 污染源码树。单变量 = cmdline 一个字符。
set -e
B=/root/star26/baseline/s220parts
S217=/root/star26/baseline/s217parts
X=/mnt/d/桌面/star26-deps/scripts/xnup_info.py
IMG=/mnt/c/ios26/s220-boot.img

mkdir -p "$B"

echo "=== [1] 组件全部照 s217 (逐字节复制) ==="
for n in loader.efi kernel ramdisk rdimage memsize identity; do
  cp -f "$S217/$n" "$B/$n"
done
for n in loader.efi kernel ramdisk rdimage memsize identity; do
  a=$(md5sum "$S217/$n" | cut -d' ' -f1); b=$(md5sum "$B/$n" | cut -d' ' -f1)
  [ "$a" = "$b" ] && echo "  $n OK $a" || { echo "  $n MISMATCH"; exit 1; }
done

echo "=== [2] cmdline: 从 s217 payload 取完整串, 只替换尾部 pac_patch=0 -> 2 ==="
CL=$(python3 - <<'PY'
import subprocess, re
out = subprocess.run(["python3", "/mnt/d/桌面/star26-deps/scripts/xnup_info.py", "/mnt/c/ios26/s217-boot.img"],
                     capture_output=True, text=True).stdout
line = [l for l in out.splitlines() if l.strip().startswith("cmdline:")][0]
cl = line.split("cmdline:", 1)[1].strip()
assert cl.endswith("pac_patch=0"), "tail not pac_patch=0: " + cl[-40:]
assert cl.count("pac_patch=") == 1, "multiple pac_patch"
print(cl[:-1] + "2")   # 只改最后一个字符 0->2
PY
)
echo "  new len=${#CL} tail=${CL: -24}"
case "$CL" in *"fb_diff=1"*) echo "  fb_diff=1 PRESENT (bad)"; exit 1;; esac

echo "=== [3] repack + reseal ==="
python3 /root/star26/hackios-xnu-kernel/xnuloader/mkpayload.py \
  -o "$B/s220-payload.bin" loader.efi="$B/loader.efi" kernel="$B/kernel" ramdisk="$B/ramdisk" \
  rdimage="$B/rdimage" \
  --cmdline "$CL" --memsize "$(tr -d '\0' < "$B/memsize")" \
  --identity "$(tr -d '\0' < "$B/identity")" 2>&1 | tail -2
python3 /root/star26/hackios-xnu-kernel/tools/reseal-loader-img.py \
  -o "$IMG" /root/star26/p2/p2-boot.img "$B/s220-payload.bin" 2>&1 | tail -2

echo "=== [4] payload-level single-variable check (s220 vs s217) ==="
python3 - <<'PY'
import subprocess, re
def secs(img):
    out = subprocess.run(["python3", "/mnt/d/桌面/star26-deps/scripts/xnup_info.py", img],
                         capture_output=True, text=True).stdout
    d = {}
    for line in out.splitlines():
        m = re.match(r"\s+(\w[\w.]*)\s+(\d+)\s+([0-9a-f]{32})", line)
        if m: d[m.group(1)] = (m.group(2), m.group(3))
    return d
a = secs("/mnt/c/ios26/s217-boot.img"); b = secs("/mnt/c/ios26/s220-boot.img")
diff = [k for k in a if k in b and a[k] != b[k]]
print("  DIFFERS:", diff)
print("  identical:", ", ".join(k for k in a if k in b and a[k] == b[k]))
assert diff == ["cmdline"], "expected ONLY cmdline to differ"
# 确认 cmdline 内容只差 pac_patch 一个字符
def cl(img):
    out = subprocess.run(["python3", "/mnt/d/桌面/star26-deps/scripts/xnup_info.py", img],
                         capture_output=True, text=True).stdout
    return [l for l in out.splitlines() if l.strip().startswith("cmdline:")][0].split("cmdline:",1)[1].strip()
ca, cb = cl("/mnt/c/ios26/s217-boot.img"), cl("/mnt/c/ios26/s220-boot.img")
assert cb == ca[:-1] + "2", "cmdline differs by more than final char"
print("  cmdline diff exact: pac_patch=0 -> pac_patch=2  (1 char)")
print("  s217 tail:", ca[-30:])
print("  s220 tail:", cb[-30:])
PY

echo "=== [5] 内核 PAC 能力自检 (确认提速代码在 s220 内核里) ==="
python3 - "$B/kernel" <<'PY'
import sys
d = open(sys.argv[1], "rb").read()
for s in [b"pac_patch", b"pac_patch_fips", b"software PAuth active"]:
    print("  '%s': %d" % (s.decode(), d.count(s)))
PY

echo "=== [6] result ==="
sha256sum "$IMG"; ls -la "$IMG"
