#!/bin/bash
# WSL-compatible one-shot runner for s93. Mirrors run-boot.sh semantics:
# grab staged bytes on ANY terminal result BEFORE any reboot; never call `oem log`.
export MSYS_NO_PATHCONV=1
F=/mnt/d/桌面/adb-fastboot/fastboot.exe
A=/mnt/d/桌面/adb-fastboot/adb.exe
TAG=s93
cd /mnt/c/ios26 || exit 1
IMG="C:/ios26/${TAG}-boot.img"
STAGED="C:/ios26/${TAG}-staged.bin"
STAGED_L="/mnt/c/ios26/${TAG}-staged.bin"

echo "=== [$(date +%T)] preflight"
ad=$("$A" devices 2>/dev/null | tr -d '\r' | grep -c "device$")
echo "adb devices count = $ad"
if [ "$ad" -lt 1 ]; then
	echo "NO ANDROID DEVICE. Checking loader/fastboot state:"
	timeout 8 "$F" getvar product 2>&1 | tr -d '\r' | grep -i product: | head -1
	echo "ABORT: expected device in Android mode"
	exit 2
fi
p=$(timeout 8 "$F" getvar product 2>&1 | tr -d '\r' | grep -i "product:" | head -1)
case "$p" in
	*xnuloader*) echo "loader debug mode: rebooting out first"; timeout 15 "$F" -s xnuloader reboot >/dev/null 2>&1; sleep 4 ;;
esac

echo "=== [$(date +%T)] adb reboot bootloader"
"$A" reboot bootloader >/dev/null 2>&1
ok=0
for i in $(seq 1 40); do
	sleep 2
	p=$(timeout 6 "$F" getvar product 2>&1 | tr -d '\r' | grep -i "product:" | head -1)
	case "$p" in *star*) echo "fastboot ready: $p (try $i)"; ok=1; break ;; esac
	if [ $((i % 10)) -eq 0 ]; then echo "  waiting fastboot... prod='${p:-none}'"; fi
done
if [ "$ok" != "1" ]; then echo "ABORT: never reached star fastboot"; exit 3; fi

echo "=== [$(date +%T)] fastboot boot ${TAG}-boot.img ($(stat -c %s "/mnt/c/ios26/${TAG}-boot.img") bytes)"
timeout 200 "$F" boot "$IMG" 2>&1 | tr -d '\r' | tail -5

rm -f "$STAGED_L"
t0=$(date +%s)
HIT=0
LAST=""
for i in $(seq 1 120); do
	sleep 2
	now=$(( $(date +%s) - t0 ))
	r=$(timeout 4 "$F" getvar result 2>&1 | tr -d '\r' | grep -i "result:" | head -1)
	LAST="$r"
	if [ -n "$r" ] && echo "$r" | grep -qiE 'checkpoint|hung|returned|early-exception|no-such-core|selftest|panic'; then
		echo "[${now}s] TERMINAL RESULT: $r"; HIT=1; break
	fi
	ad=$("$A" devices 2>/dev/null | tr -d '\r' | grep -c "device$")
	if [ "$ad" -gt 0 ]; then echo "[${now}s] ANDROID BACK (cold reset)"; break; fi
	pr=$(timeout 4 "$F" getvar product 2>&1 | tr -d '\r' | grep -i "product:" | head -1)
	case "$pr" in *star*) echo "[${now}s] ABL FASTBOOT (cold reset)"; break ;; esac
	if [ $((i % 15)) -eq 0 ]; then echo "[${now}s] result='${r:-none}' product='${pr:-none}'"; fi
done
echo "last result: '${LAST:-none}' HIT=$HIT"

if [ "$HIT" = "1" ]; then
	echo "=== [$(date +%T)] get_staged (before any reboot)"
	for try in 1 2 3; do
		timeout 45 "$F" -s xnuloader get_staged "$STAGED" 2>&1 | tr -d '\r' | tail -3
		if [ -s "$STAGED_L" ]; then echo "captured $(stat -c %s "$STAGED_L") bytes"; break; fi
		sleep 2
	done
else
	echo "=== no loader terminal result; trying oem log + get_staged once"
	timeout 30 "$F" -s xnuloader oem log >/dev/null 2>&1
	timeout 45 "$F" -s xnuloader get_staged "$STAGED" 2>&1 | tr -d '\r' | tail -3
	[ -s "$STAGED_L" ] && echo "captured $(stat -c %s "$STAGED_L") bytes"
fi

echo "=== [$(date +%T)] analysis"
python3 - "$STAGED_L" <<'PY'
import sys, os
p = sys.argv[1]
if not os.path.exists(p) or os.path.getsize(p) == 0:
    print("---", p, "(empty/missing — no live log captured)")
    sys.exit(0)
d = open(p, "rb").read()
t = d.decode("utf-8", "replace").replace("\0", "")
print("---", p, len(d), "bytes,", len(t), "text chars")
pats = ["== XNULOADER", "jumping to", "== KERNEL LOG ==", "STAR0:",
        "STARX", "star: milestone", "FAULT:", "PANIC caller",
        "Darwin Kernel", "SecTaskLoadEntitlements", "error=22",
        "cs_flags=26000000", "NOT_CODESIGNED", "star_kv:",
        "acquired main display digitizer", "registration completed",
        "SpringBoard", "backboardd"]
for x in pats:
    print("   %-38s %d" % (x, t.count(x)))
k = t.find("== KERNEL LOG ==")
print("=== error=22 context (all) ===")
idx = 0
while True:
    idx = t.find("error=22", idx)
    if idx < 0: break
    print("   ...", t[max(0,idx-90):idx+90].replace("\n"," "))
    idx += 8
print("=== star_kv context ===")
idx = 0
while True:
    idx = t.find("star_kv", idx)
    if idx < 0: break
    print("   ...", t[max(0,idx-40):idx+120].replace("\n"," "))
    idx += 7
PY
echo "=== [$(date +%T)] DONE"
