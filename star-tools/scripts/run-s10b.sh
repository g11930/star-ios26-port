#!/bin/bash
# s10b: same s10-boot.img, different capture discipline.
#
# s10 lost the log because it asked `getvar result` every 3 s and gave up after the
# first empty answer; s7 got the log because it happened to ask inside the window.
# The kernel's ring holds the panic ~2-3 s after the jump, so ask fast and grab at
# the first sign of life, then keep grabbing while the endpoint answers.
export MSYS_NO_PATHCONV=1
F=fastboot.exe
A=adb.exe
DIR=/c/ios26
LOG=$DIR/s10b-run.log
: > "$LOG"

say() { echo "[$(date +%H:%M:%S)] $*" >> "$LOG"; }
q() { timeout 5 "$F" -s xnuloader "$@" 2>&1 | tr -d '\r'; }

say "=== s10b: same image, 0.4 s polling, grab on first non-idle ==="
prod=$(timeout 10 "$F" getvar product 2>&1 | tr -d '\r' | grep -i "product:" | head -1)
if [ -z "$prod" ]; then
	say "FATAL: not in fastboot (want product: star), nothing flashed"; exit 1
fi
say "fastboot up: $prod"
cd "$DIR" || exit 1
say "fastboot boot s10-boot.img"
timeout 150 "$F" boot s10-boot.img >> "$LOG" 2>&1
say "boot returned (rc=$?)"

# Wait for the loader's USB to answer at all, then stop treating "idle" as interest.
got=0
n=0
while [ $n -lt 150 ]; do
	n=$((n+1))
	s=$(q getvar result | grep -i "result:" | head -1)
	if [ -n "$s" ]; then
		say "[$n] $s"
		case "$s" in
			*idle*) : ;;                       # loader still counting down
			*)
				# `oem log` is what makes the loader snapshot the kernel's ring;
				# get_staged only carries the snapshot out (that is s7's order).
				q oem log >> "$LOG" 2>&1
				f=/c/ios26/s10b-$n.bin
				rm -f "$f"
				timeout 30 "$F" -s xnuloader get_staged "$f" >/dev/null 2>&1
				sz=$(stat -c %s "$f" 2>/dev/null || echo 0)
				if [ "$sz" -gt 0 ]; then
					say "  GRAB s10b-$n.bin $sz bytes  <- $s"
					got=1
				fi
				;;
		esac
	else
		# empty answer: endpoint is gone. Keep trying a few times, then stop.
		:
	fi
	if [ "$got" -eq 1 ]; then
		# keep grabbing while it works (the ring grows with the panic), then stop
		for k in 1 2 3 4 5; do
			f=/c/ios26/s10b-$n-$k.bin
			rm -f "$f"
			timeout 20 "$F" -s xnuloader get_staged "$f" >/dev/null 2>&1
			sz=$(stat -c %s "$f" 2>/dev/null || echo 0)
			[ "$sz" -gt 0 ] && say "  GRAB s10b-$n-$k.bin $sz bytes" || rm -f "$f"
			sleep 2
		done
		break
	fi
	if "$A" devices 2>/dev/null | grep -q "device$"; then say "[$n] Android is back"; break; fi
	sleep 0.4
done

say "got_any=$got"
say "--- oem screenshot (if the endpoint is still there) ---"
q oem screenshot >> "$LOG" 2>&1
rm -f /c/ios26/s10b-screen.bin
timeout 60 "$F" -s xnuloader get_staged /c/ios26/s10b-screen.bin >> "$LOG" 2>&1
say "  screen.bin $(stat -c %s /c/ios26/s10b-screen.bin 2>/dev/null || echo 0) bytes"
q oem stop >> "$LOG" 2>&1
say "DONE"
tail -40 "$LOG"
