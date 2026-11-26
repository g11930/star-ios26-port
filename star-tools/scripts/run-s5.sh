#!/bin/bash
# s5: verify WHICH loader is running, then capture live kernel logs/pixels.
#
# New in s5 (lesson from s4):
#   * `getvar build-id` must equal star-s5-stage6 -- otherwise the phone is
#     executing some other loader copy and stage-6 cannot be in effect.
#   * `getvar result` says "idle" while the boot menu is still counting down.
#     Do NOT start capturing until it says "running" (s4 captured too early
#     and got only 2074 bytes of the loader's own prefix).
#   * Short, bounded timeouts.  s4's get_staged attempts hung for 14 minutes.
#   * If USB never answers, fall back to the logdump partition after Android
#     comes back (only the first ~8 KB is the current boot -- see memory).
export MSYS_NO_PATHCONV=1
A=adb.exe
F=fastboot.exe
DIR=/c/ios26
LOG=$DIR/s5-run.log
WANT=star-s5-stage6
: > "$LOG"

say() { echo "[$(date +%H:%M:%S)] $*" >> "$LOG"; }
q() { timeout 6 "$F" -s xnuloader "$@" 2>&1 | tr -d '\r'; }
grab() { # grab <file> ; caller stages first
	local f=$1
	rm -f "$f"
	timeout 45 "$F" -s xnuloader get_staged "$f" >> "$LOG" 2>&1
	say "  $f $(stat -c %s "$f" 2>/dev/null || echo 0) bytes"
}

say "=== s5: stage-6 loader + build-id identity check ==="
"$A" kill-server >> "$LOG" 2>&1
sleep 1
timeout 60 "$A" reboot bootloader >> "$LOG" 2>&1

up=0
for i in $(seq 1 60); do
	prod=$(timeout 10 "$F" getvar product 2>&1 | tr -d '\r' | grep -i "product:" | head -1)
	if [ -n "$prod" ]; then say "fastboot up at try $i: $prod"; up=1; break; fi
	sleep 2
done
if [ "$up" -ne 1 ]; then say "FATAL: fastboot never answered; no flash"; exit 1; fi

cd "$DIR" || exit 1
say "fastboot boot s5-boot.img"
timeout 150 "$F" boot s5-boot.img >> "$LOG" 2>&1
say "boot command returned (rc=$?)"

# --- 1. wait for the loader's USB, then ask which binary is running --------
loader_up=0
for i in $(seq 1 30); do
	sleep 2
	r=$(q getvar result)
	if echo "$r" | grep -qi "result:"; then
		say "[$i] USB alive: $(echo "$r" | grep -i 'result:' | head -1)"
		loader_up=1
		break
	fi
	if [ $((i % 5)) -eq 0 ]; then say "[$i] no loader USB yet"; fi
done
say "LOADER_USB=$loader_up"

if [ "$loader_up" -eq 1 ]; then
	bid=$(q getvar build-id | grep -i "build-id:" | head -1)
	say "BUILD-ID: ${bid:-<none>}"
	case "$bid" in
		*"$WANT"*) say "IDENTITY OK: the freshly built s5 loader is running" ;;
		*) say "IDENTITY MISMATCH: phone is NOT running the s5 loader (FD/partition copy?)" ;;
	esac
	prod=$(q getvar product | grep -i "product:" | head -1)
	say "PRODUCT: ${prod:-<none>}"

	# --- 2. wait until the kernel is actually running ----------------------
	running=0
	for i in $(seq 1 40); do
		r=$(q getvar result)
		s=$(echo "$r" | grep -i "result:" | head -1)
		[ -n "$s" ] && say "[$i] $s"
		case "$s" in
			*running*) running=1; break ;;
			*returned*|*hung-held*) break ;;
		esac
		if "$A" devices 2>/dev/null | grep -q "device$"; then say "[$i] Android is back"; break; fi
		sleep 2
	done
	say "KERNEL_RUNNING=$running"

	# --- 3. capture the live kernel log repeatedly, then the panel --------
	if [ "$running" -eq 1 ]; then
		for n in 1 2 3 4 5; do
			say "--- live capture #$n ---"
			q oem log >> "$LOG" 2>&1
			grab "s5-klog-$n.bin"
			sleep 3
		done
		geom=$(q getvar screen | grep -i "screen:" | head -1)
		say "SCREEN geometry: ${geom:-<none>}"
		q oem screenshot >> "$LOG" 2>&1
		grab s5-screen.bin
	fi

	say "--- ask the kernel to return ---"
	q oem stop >> "$LOG" 2>&1
	for i in $(seq 1 20); do
		sleep 3
		s=$(q getvar result | grep -i "result:" | head -1)
		[ -n "$s" ] && say "[$i] $s"
		case "$s" in *returned*|*hung-held*) break ;; esac
		if "$A" devices 2>/dev/null | grep -q "device$"; then say "[$i] Android is back"; break; fi
	done
	# Returned: go STRAIGHT to get_staged, never `oem log` (would overwrite).
	grab s5-final.bin
else
	say "USB never answered -- wait for Android, then read logdump"
	for i in $(seq 1 24); do
		if "$A" devices 2>/dev/null | grep -q "device$"; then say "Android is back at try $i"; break; fi
		sleep 5
	done
	say "run: bash D:/桌面/star26-deps/scripts/fetch-logdump.sh s5"
fi

say "DONE"
tail -70 "$LOG"
