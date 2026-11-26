#!/bin/bash
# s10: same image as s7 in every byte but the kernel. The kernel now writes a
# STARSP line (sp/fp/pc/lr/cpsr/kstack top) into the loader's log ring *before*
# the register table that the 958-byte log budget truncates at x24, and the
# pac_emu notes bypass printf() (stripped by CONFIG_NO_PRINTF_STRINGS).
#
# Capture order is s7's, which is the one that worked: as soon as `result` says
# running, `oem log` + get_staged immediately (the panic is in the live ring ~3 s
# after the jump); on hung-held/returned, grab again, then the raw framebuffer.
export MSYS_NO_PATHCONV=1
A=adb.exe
F=fastboot.exe
DIR=/c/ios26
LOG=$DIR/s10-run.log
: > "$LOG"

say() { echo "[$(date +%H:%M:%S)] $*" >> "$LOG"; }
q() { timeout 8 "$F" -s xnuloader "$@" 2>&1 | tr -d '\r'; }
grab() {
	local f=$1
	rm -f "$f"
	timeout 90 "$F" -s xnuloader get_staged "$f" >> "$LOG" 2>&1
	say "  $f $(stat -c %s "$f" 2>/dev/null || echo 0) bytes"
}

say "=== s10: STARSP diagnostic kernel, s7 cmdline ==="
# The phone is usually already sitting in fastboot after a failed run; only go
# through adb when it is not, because the adb round trip costs a minute.
up=0
prod=$(timeout 10 "$F" getvar product 2>&1 | tr -d '\r' | grep -i "product:" | head -1)
if [ -n "$prod" ]; then say "fastboot already up: $prod"; up=1; fi
if [ "$up" -ne 1 ]; then
	"$A" kill-server >> "$LOG" 2>&1
	sleep 1
	for i in $(seq 1 30); do
		if "$A" devices 2>/dev/null | grep -q "device$"; then say "adb sees the phone at try $i"; break; fi
		sleep 2
	done
	timeout 60 "$A" reboot bootloader >> "$LOG" 2>&1
	say "reboot bootloader sent (rc=$?)"
	for i in $(seq 1 60); do
		prod=$(timeout 10 "$F" getvar product 2>&1 | tr -d '\r' | grep -i "product:" | head -1)
		if [ -n "$prod" ]; then say "fastboot up at try $i: $prod"; up=1; break; fi
		sleep 2
	done
fi
if [ "$up" -ne 1 ]; then say "FATAL: fastboot never answered; no flash"; exit 1; fi

cd "$DIR" || exit 1
say "fastboot boot s10-boot.img"
timeout 150 "$F" boot s10-boot.img >> "$LOG" 2>&1
say "boot command returned (rc=$?)"

loader_up=0
for i in $(seq 1 40); do
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
	say "USB never answered; waiting for Android"
	for i in $(seq 1 30); do
		if "$A" devices 2>/dev/null | grep -q "device$"; then say "Android back at try $i"; break; fi
		sleep 5
	done
	say "DONE (usb-less)"; tail -40 "$LOG"; exit 0
fi

got_live=0
for i in $(seq 1 120); do
	sleep 3
	s=$(q getvar result | grep -i "result:" | head -1)
	[ -n "$s" ] && say "[$i] $s"
	case "$s" in
		*running*)
			if [ "$got_live" -eq 0 ]; then
				say "--- STARSP kernel is running: live ring ---"
				q oem log >> "$LOG" 2>&1
				grab s10-live.bin
				got_live=1
			fi
			;;
		*hung*|*returned*|*exception*|*fault*)
			say "STATE at [ $i ]: $s"
			break
			;;
	esac
	if [ "$got_live" -eq 1 ]; then
		case "$s" in *running*) ;; *) break ;; esac
	fi
	if "$A" devices 2>/dev/null | grep -q "device$"; then say "[$i] Android is back"; break; fi
done

say "--- collecting (no `oem log` first: it would compose_logs(NULL,0) over the panic) ---"
grab s10-final.bin
q oem screenshot >> "$LOG" 2>&1
grab s10-screen.bin
q oem log >> "$LOG" 2>&1
grab s10-log2.bin

say "--- oem stop ---"
q oem stop >> "$LOG" 2>&1
for i in $(seq 1 15); do
	sleep 2
	s=$(q getvar result | grep -i "result:" | head -1)
	[ -n "$s" ] && say "[$i] $s"
	case "$s" in *returned*|*hung-held*) break ;; esac
	if "$A" devices 2>/dev/null | grep -q "device$"; then say "Android is back"; break; fi
done
grab s10-final2.bin

say "DONE"
tail -60 "$LOG"
