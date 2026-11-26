#!/bin/bash
# s7: the display/GPU ABI layer is in the kernel. Goal: reach the iOS desktop.
#
# The cmdline gives the kernel 200 s before the controlled hand-back, so this
# run has time to bring WindowServer up.  If the kernel's heartbeat never
# reaches the loader, SILENCE_SECONDS=50 resets the phone first -- the screen
# is then the only evidence, so watch it.
#
# Capture order (learned from P39/P40/s4):
#   while running -> `oem log` + get_staged   (live ring from memory)
#   on returned   -> get_staged IMMEDIATELY   (the full kernel log)
#   then          -> `oem screenshot` + get_staged (raw 0xEA600000 pixels)
export MSYS_NO_PATHCONV=1
A=adb.exe
F=fastboot.exe
DIR=/c/ios26
LOG=$DIR/s7-run.log
WANT=star-s5-stage6
: > "$LOG"

say() { echo "[$(date +%H:%M:%S)] $*" >> "$LOG"; }
q() { timeout 8 "$F" -s xnuloader "$@" 2>&1 | tr -d '\r'; }
grab() {
	local f=$1
	rm -f "$f"
	timeout 60 "$F" -s xnuloader get_staged "$f" >> "$LOG" 2>&1
	say "  $f $(stat -c %s "$f" 2>/dev/null || echo 0) bytes"
}

say "=== s7: display ABI layer + 200 s return window ==="
"$A" kill-server >> "$LOG" 2>&1
sleep 1
# After kill-server the daemon has to see the phone again before it accepts a
# command; asking too early fails with "no devices/emulators found".
for i in $(seq 1 30); do
	if "$A" devices 2>/dev/null | grep -q "device$"; then say "adb sees the phone at try $i"; break; fi
	sleep 2
done
timeout 60 "$A" reboot bootloader >> "$LOG" 2>&1
say "reboot bootloader sent (rc=$?)"

up=0
for i in $(seq 1 60); do
	prod=$(timeout 10 "$F" getvar product 2>&1 | tr -d '\r' | grep -i "product:" | head -1)
	if [ -n "$prod" ]; then say "fastboot up at try $i: $prod"; up=1; break; fi
	sleep 2
done
if [ "$up" -ne 1 ]; then say "FATAL: fastboot never answered; no flash"; exit 1; fi

cd "$DIR" || exit 1
say "fastboot boot s7-boot.img"
timeout 150 "$F" boot s7-boot.img >> "$LOG" 2>&1
say "boot command returned (rc=$?)"

loader_up=0
for i in $(seq 1 30); do
	sleep 2
	r=$(q getvar result)
	if echo "$r" | grep -qi "result:"; then
		say "[$i] USB alive: $(echo "$r" | grep -i 'result:' | head -1)"
		loader_up=1
		break
	fi
done
say "LOADER_USB=$loader_up"

if [ "$loader_up" -ne 1 ]; then
	say "USB never answered; wait for Android then read logdump"
	for i in $(seq 1 30); do
		if "$A" devices 2>/dev/null | grep -q "device$"; then say "Android back at try $i"; break; fi
		sleep 5
	done
	say "DONE (usb-less)"
	tail -50 "$LOG"
	exit 0
fi

bid=$(q getvar build-id | grep -i "build-id:" | head -1)
say "BUILD-ID: ${bid:-<none>}"
case "$bid" in
	*"$WANT"*) say "IDENTITY OK" ;;
	*) say "IDENTITY MISMATCH" ;;
esac

# --- watch the state machine for up to ~6 minutes ------------------------
got_live=0
returned=0
for i in $(seq 1 120); do
	sleep 3
	r=$(q getvar result)
	s=$(echo "$r" | grep -i "result:" | head -1)
	[ -n "$s" ] && say "[$i] $s"
	case "$s" in
		*running*)
			if [ "$got_live" -eq 0 ]; then
				say "--- live snapshot while the kernel runs ---"
				q oem log >> "$LOG" 2>&1
				grab s7-klog-live.bin
				got_live=1
			fi
			;;
		*returned*)
			say "RETURNED at [ $i ] -- controlled hand-back"
			returned=1
			break
			;;
		*hung-held*)
			say "HUNG-HELD at [ $i ]"
			break
			;;
	esac
	if "$A" devices 2>/dev/null | grep -q "device$"; then say "[$i] Android is back"; break; fi
done
say "RETURNED=$returned"

grab s7-final.bin
q oem screenshot >> "$LOG" 2>&1
grab s7-screen.bin
q oem log >> "$LOG" 2>&1
grab s7-klog-2.bin

say "--- oem stop ---"
q oem stop >> "$LOG" 2>&1
for i in $(seq 1 15); do
	sleep 2
	s=$(q getvar result | grep -i "result:" | head -1)
	[ -n "$s" ] && say "[$i] $s"
	case "$s" in *returned*|*hung-held*) break ;; esac
	if "$A" devices 2>/dev/null | grep -q "device$"; then say "Android is back"; break; fi
done
grab s7-final2.bin

say "DONE"
tail -60 "$LOG"
