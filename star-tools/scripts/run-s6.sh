#!/bin/bash
# s6: kernel returns at 45 s (loader_return_after=45 < SILENCE_SECONDS=50),
# so the loader survives, write_logs() flushes the FULL kernel log, and
# fastboot stays answerable -- we no longer depend on a photo of the screen.
#
# Capture order matters (learned the hard way on P39/P40/s4):
#   * while running  -> `oem log` + get_staged   (compose_live_log from memory)
#   * on returned    -> get_staged IMMEDIATELY   (`oem log` would overwrite it)
#   * then           -> `oem screenshot` + get_staged  (raw 0xEA600000 pixels)
#   * finally        -> `oem log` + get_staged   (one more live snapshot)
export MSYS_NO_PATHCONV=1
A=adb.exe
F=fastboot.exe
DIR=/c/ios26
LOG=$DIR/s6-run.log
WANT=star-s5-stage6
: > "$LOG"

say() { echo "[$(date +%H:%M:%S)] $*" >> "$LOG"; }
q() { timeout 8 "$F" -s xnuloader "$@" 2>&1 | tr -d '\r'; }
grab() { # grab <file> ; caller stages first
	local f=$1
	rm -f "$f"
	timeout 60 "$F" -s xnuloader get_staged "$f" >> "$LOG" 2>&1
	say "  $f $(stat -c %s "$f" 2>/dev/null || echo 0) bytes"
}

say "=== s6: loader_return_after=45, no -v (p12 shape) ==="
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
say "fastboot boot s6-boot.img"
timeout 150 "$F" boot s6-boot.img >> "$LOG" 2>&1
say "boot command returned (rc=$?)"

# --- 1. wait for the loader's USB, then confirm which binary is running ----
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

if [ "$loader_up" -ne 1 ]; then
	say "USB never answered -- wait for Android, then read logdump"
	for i in $(seq 1 30); do
		if "$A" devices 2>/dev/null | grep -q "device$"; then say "Android is back at try $i"; break; fi
		sleep 5
	done
	say "DONE (usb-less)"
	tail -60 "$LOG"
	exit 0
fi

bid=$(q getvar build-id | grep -i "build-id:" | head -1)
say "BUILD-ID: ${bid:-<none>}"
case "$bid" in
	*"$WANT"*) say "IDENTITY OK: the s5/s6 loader is running" ;;
	*) say "IDENTITY MISMATCH: phone is NOT running our loader" ;;
esac

# --- 2. watch result: idle -> running -> returned -------------------------
got_live=0
returned=0
for i in $(seq 1 45); do
	sleep 2
	r=$(q getvar result)
	s=$(echo "$r" | grep -i "result:" | head -1)
	[ -n "$s" ] && say "[$i] $s"
	case "$s" in
		*running*)
			if [ "$got_live" -eq 0 ]; then
				say "--- live snapshot while the kernel runs ---"
				q oem log >> "$LOG" 2>&1
				grab s6-klog-live.bin
				got_live=1
			fi
			;;
		*returned*)
			say "RETURNED at [ $i ] -- the kernel handed control back"
			returned=1
			break
			;;
		*hung-held*)
			say "HUNG-HELD at [ $i ] -- watchdog still won"
			break
			;;
	esac
	if "$A" devices 2>/dev/null | grep -q "device$"; then say "[$i] Android is back"; break; fi
done
say "RETURNED=$returned"

# --- 3. the log the loader flushed on return: grab it FIRST ---------------
grab s6-final.bin

# --- 4. panel pixels (loader UI, since -v is gone) ------------------------
q oem screenshot >> "$LOG" 2>&1
grab s6-screen.bin

# --- 5. one more live snapshot -------------------------------------------
q oem log >> "$LOG" 2>&1
grab s6-klog-2.bin

# --- 6. let the loader go ------------------------------------------------
say "--- oem stop ---"
q oem stop >> "$LOG" 2>&1
for i in $(seq 1 15); do
	sleep 2
	s=$(q getvar result | grep -i "result:" | head -1)
	[ -n "$s" ] && say "[$i] $s"
	case "$s" in *returned*|*hung-held*) break ;; esac
	if "$A" devices 2>/dev/null | grep -q "device$"; then say "[$i] Android is back"; break; fi
done
grab s6-final2.bin

say "DONE"
tail -80 "$LOG"
