#!/bin/bash
# One-shot s20 run: boot, watch `getvar result`, and grab the log through the
# right channel the instant it becomes available.
#
# Two failure windows we already hit in earlier rounds:
#  - `oem log` in a returned state recomposes from NULL and wipes the staged
#    bytes, so it must never be called here.
#  - A checkpoint that hits while the kernel holds UFS is `checkpoint-held`:
#    the loader does not write logdump, the bytes live only in its staging
#    area, and `fastboot -s xnuloader reboot` destroys them for good.
# Hence: poll `getvar result` (a real getvar field in loader_06_usb_entry.inc),
# fire `get_staged` on the first `checkpoint` answer, and only reboot after the
# bytes are on disk.  If instead Android comes back, read logdump via dd.
export MSYS_NO_PATHCONV=1
cd /c/ios26 || exit 1
F=fastboot.exe
A=adb.exe
IMG=s20-boot.img
STAGED=s20-staged.bin
DUMP=s20-log.bin

echo "=== preflight"
p=$(timeout 8 "$F" getvar product 2>&1 | tr -d '\r' | grep -i "product:" | head -1)
echo "start: ${p:-<no fastboot>}"
case "$p" in
	*xnuloader*)
		echo "loader debug mode: rebooting"
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
timeout 200 "$F" boot "$IMG" 2>&1 | tr -d '\r' | tail -3

rm -f "$STAGED" "$DUMP"
t0=$(date +%s)
HIT=0
for i in $(seq 1 100); do
	sleep 2
	now=$(( $(date +%s) - t0 ))

	r=$(timeout 4 "$F" getvar result 2>&1 | tr -d '\r' | grep -i "result:" | head -1)
	if [ -n "$r" ] && echo "$r" | grep -qi "checkpoint"; then
		echo "[${now}s] CHECKPOINT RESULT: $r"
		HIT=1
		break
	fi

	ad=$("$A" devices 2>/dev/null | grep -c "device$")
	if [ "$ad" -gt 0 ]; then
		echo "[${now}s] ANDROID BACK (kernel died / cold reset)"
		break
	fi

	pr=$(timeout 4 "$F" getvar product 2>&1 | tr -d '\r' | grep -i "product:" | head -1)
	case "$pr" in
		*star*) echo "[${now}s] ABL FASTBOOT (cold reset)"; break ;;
	esac

	if [ $((i % 10)) -eq 0 ]; then echo "[${now}s] result='${r:-none}' product='${pr:-none}'"; fi
done

if [ "$HIT" = "1" ]; then
	echo "=== get_staged (before any reboot)"
	for try in 1 2 3; do
		timeout 40 "$F" -s xnuloader get_staged "$STAGED" 2>&1 | tr -d '\r' | tail -3
		if [ -s "$STAGED" ]; then echo "captured $(stat -c %s "$STAGED") bytes"; break; fi
		sleep 1
	done
	echo "=== now safe to reboot out of loader debug mode"
	timeout 15 "$F" -s xnuloader reboot >/dev/null 2>&1
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
python3 - "$STAGED" "$DUMP" <<'PY'
import sys, os
for p in sys.argv[1:]:
    if not os.path.exists(p) or os.path.getsize(p) == 0:
        print("---", p, "(empty/missing)"); continue
    d = open(p, "rb").read()
    t = d.decode("utf-8", "replace").replace("\0", "")
    print("---", p, len(d), "bytes,", len(t), "text chars")
    for pat in ("== XNULOADER", "result:", "jumping to", "== KERNEL LOG ==",
                "STARX", "star: milestone", "the kernel came back", "STARSP"):
        print("   %-24s %d" % (pat, t.count(pat)))
    r = t.find("result:")
    print("=== result ===")
    print(t[r:r+200] if r > 0 else "(none)")
    k = t.find("== KERNEL LOG ==")
    print("=== kernel section ===")
    print(t[k:k+6000] if k > 0 else "(no marker)")
PY
echo "=== done"
