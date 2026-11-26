#!/bin/bash
# s8: the kalloc constants now match this kernel. If the early panic is gone the
# kernel should get past kalloc_type_view_parse and into bsd_init.
#
# New in s8: while the kernel is RUNNING we dump the panel too (oem screenshot
# reads 0xEA600000 directly), so a desktop shows up in the staged blobs instead
# of only on the phone.  s7 only dumped it after the hang, which is why the
# first picture we saw was the loader's fault panel.
export MSYS_NO_PATHCONV=1
A=adb.exe
F=fastboot.exe
DIR=/c/ios26
LOG=$DIR/s8-run.log
: > "$LOG"

say() { echo "[$(date +%H:%M:%S)] $*" >> "$LOG"; }
q() { timeout 8 "$F" -s xnuloader "$@" 2>&1 | tr -d '\r'; }
grab() {
	local f=$1
	rm -f "$f"
	timeout 90 "$F" -s xnuloader get_staged "$f" >> "$LOG" 2>&1
	say "  $f $(stat -c %s "$f" 2>/dev/null || echo 0) bytes"
}
shot() { # shot <n>  -- panel pixels while the kernel runs
	q oem screenshot >> "$LOG" 2>&1
	grab "s8-screen-$1.bin"
}

say "=== s8: kalloc constants fixed for this build ==="
"$A" kill-server >> "$LOG" 2>&1
sleep 1
for i in $(seq 1 30); do
	if "$A" devices 2>/dev/null | grep -q "device$"; then say "adb sees the phone at try $i"; break; fi
	sleep 2
done
timeout 60 "$A" reboot bootloader >> "$LOG" 2>&1
say "reboot bootloader sent (rc=$?)"

up=0
for i in $(seq 1 60); do
	prod=$(timeout 10 "$F" getvar product 2>&1 | tr -d '\r' | grep -i "product:" | head -1)
	if [ -n "$prod" ]; then say "fastboot up: $prod"; up=1; break; fi
	sleep 2
done
if [ "$up" -ne 1 ]; then say "FATAL: no fastboot"; exit 1; fi

cd "$DIR" || exit 1
say "fastboot boot s8-boot.img"
timeout 150 "$F" boot s8-boot.img >> "$LOG" 2>&1
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
	for i in $(seq 1 30); do
		if "$A" devices 2>/dev/null | grep -q "device$"; then say "Android back at try $i"; break; fi
		sleep 5
	done
	say "DONE (usb-less)"; tail -40 "$LOG"; exit 0
fi

say "BUILD-ID: $(q getvar build-id | grep -i 'build-id:' | head -1)"

got_live=0
shots=0
returned=0
for i in $(seq 1 140); do
	sleep 3
	s=$(q getvar result 2>/dev/null | grep -i "result:" | head -1)
	[ -n "$s" ] && say "[$i] $s"
	case "$s" in
		*running*)
			if [ "$got_live" -eq 0 ]; then
				say "--- kernel is running: live log ---"
				q oem log >> "$LOG" 2>&1
				grab s8-klog-live.bin
				got_live=1
			fi
			# first panel dump ~15 s in, then every ~45 s
			if [ "$shots" -eq 0 ] && [ "$i" -ge 5 ]; then
				say "--- panel dump #1 ---"; shot 1; shots=1
			elif [ "$shots" -eq 1 ] && [ "$i" -ge 20 ]; then
				say "--- panel dump #2 ---"; shot 2; shots=2
			elif [ "$shots" -eq 2 ] && [ "$i" -ge 45 ]; then
				say "--- panel dump #3 ---"; shot 3; shots=3
			fi
			;;
		*returned*) say "RETURNED at [ $i ]"; returned=1; break ;;
		*hung-held*) say "HUNG-HELD at [ $i ]"; break ;;
	esac
	if "$A" devices 2>/dev/null | grep -q "device$"; then say "[$i] Android is back"; break; fi
done
say "RETURNED=$returned"

grab s8-final.bin
shot final
q oem log >> "$LOG" 2>&1
grab s8-klog-2.bin

say "--- oem stop ---"
q oem stop >> "$LOG" 2>&1
for i in $(seq 1 12); do
	sleep 2
	s=$(q getvar result | grep -i "result:" | head -1)
	[ -n "$s" ] && say "[$i] $s"
	case "$s" in *returned*|*hung-held*) break ;; esac
	if "$A" devices 2>/dev/null | grep -q "device$"; then say "Android is back"; break; fi
done
grab s8-final2.bin

say "DONE"
tail -50 "$LOG"
