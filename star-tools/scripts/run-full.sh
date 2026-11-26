#!/bin/bash
# run-full.sh <tag> [seconds]
# Full-boot probe: no checkpoint.  Distinguishes
#   * terminal result (returned / hung / checkpoint) -> staged log
#   * kernel alive and heartbeating ("running")     -> keep it running, try a screenshot
#   * cold reset back to Android                    -> logdump
export MSYS_NO_PATHCONV=1
TAG=${1:?usage: run-full.sh s27 [seconds]}
WAIT=${2:-150}
cd /c/ios26 || exit 1
F=fastboot.exe
A=adb.exe
IMG=$TAG-boot.img
STAGED=$TAG-staged.bin
DUMP=$TAG-log.bin

echo "=== preflight ($TAG)"
p=$(timeout 8 "$F" getvar product 2>&1 | tr -d '\r' | grep -i "product:" | head -1)
echo "start: ${p:-<no fastboot>}"
case "$p" in
	*xnuloader*)
		timeout 15 "$F" -s xnuloader reboot >/dev/null 2>&1
		;;
esac
for i in $(seq 1 30); do
	sleep 3
	if "$A" devices 2>/dev/null | grep -q "device$"; then echo "android at try $i"; break; fi
done
sleep 2
"$A" reboot bootloader >/dev/null 2>&1
for i in $(seq 1 30); do
	sleep 3
	p=$(timeout 8 "$F" getvar product 2>&1 | tr -d '\r' | grep -i "product:" | head -1)
	case "$p" in *star*) echo "fastboot: $p"; break ;; esac
done

echo "=== flashing $IMG ($(stat -c %s "$IMG") bytes)"
timeout 200 "$F" boot "$IMG" 2>&1 | tr -d '\r' | tail -2

rm -f "$STAGED" "$DUMP"
t0=$(date +%s)
HIT=0
ALIVE=0
SHOT=0
for i in $(seq 1 $((WAIT / 2))); do
	sleep 2
	now=$(( $(date +%s) - t0 ))
	r=$(timeout 4 "$F" getvar result 2>&1 | tr -d '\r' | grep -i "result:" | head -1)
	if [ -n "$r" ] && echo "$r" | grep -qiE 'checkpoint|hung|returned|early-exception|no-such-core|selftest'; then
		echo "[${now}s] TERMINAL RESULT: $r"
		HIT=1
		break
	fi
	case "$r" in
		*result:\ running*)
			ALIVE=$((ALIVE + 1))
			;;
	esac
	if [ "$now" -ge 60 ] && [ "$SHOT" = "0" ] && [ "$ALIVE" -ge 5 ]; then
		echo "[${now}s] kernel still running (${ALIVE} polls): taking a screenshot"
		timeout 30 "$F" -s xnuloader oem screenshot "$TAG-shot.png" 2>&1 | tr -d '\r' | tail -2
		SHOT=1
	fi
	ad=$("$A" devices 2>/dev/null | grep -c "device$")
	if [ "$ad" -gt 0 ]; then echo "[${now}s] ANDROID BACK (cold reset)"; break; fi
	pr=$(timeout 4 "$F" getvar product 2>&1 | tr -d '\r' | grep -i "product:" | head -1)
	case "$pr" in *star*) echo "[${now}s] ABL FASTBOOT (cold reset)"; break ;; esac
	if [ $((i % 10)) -eq 0 ]; then echo "[${now}s] result='${r:-none}' alive_polls=$ALIVE"; fi
done

if [ "$HIT" = "1" ]; then
	echo "=== get_staged (before any reboot)"
	for try in 1 2 3; do
		timeout 40 "$F" -s xnuloader get_staged "$STAGED" 2>&1 | tr -d '\r' | tail -2
		if [ -s "$STAGED" ]; then echo "captured $(stat -c %s "$STAGED") bytes"; break; fi
		sleep 1
	done
elif [ "$ALIVE" -ge 5 ]; then
	echo "=== KERNEL IS ALIVE: leaving it running (no reboot, no staged read)"
else
	echo "=== pull logdump via dd from Android"
	for i in $(seq 1 30); do
		sleep 3
		if "$A" devices 2>/dev/null | grep -q "device$"; then break; fi
	done
	"$A" shell "su -c 'dd if=/dev/block/sda24 bs=4096 count=2048 2>/dev/null | base64'" \
		| tr -d '\r\n ' | base64 -d > "$DUMP"
	ls -la "$DUMP"
fi

echo "=== analysis"
python3 - "$STAGED" <<'PY'
import sys, os
p = sys.argv[1]
if not os.path.exists(p) or os.path.getsize(p) == 0:
    print("--- %s (empty/missing)" % p)
else:
    d = open(p, "rb").read()
    t = d.decode("utf-8", "replace").replace("\0", "")
    print("--- %s %d bytes" % (p, len(d)))
    k = t.find("== KERNEL LOG ==")
    print(t[k:k+4000] if k > 0 else t[:2000])
PY
echo "=== done"
