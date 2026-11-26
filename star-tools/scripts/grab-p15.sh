#!/bin/bash
# P15: boot the iOS26 payload, then grab the staged klog as soon as the loader
# comes back into its fallback fastboot mode (it self-reboots after 120s idle).
export MSYS_NO_PATHCONV=1

FB="/d/桌面/adb-fastboot/fastboot.exe"
ADB="/d/桌面/adb-fastboot/adb.exe"
IMG="/d/桌面/star26-deps/引导/p14-boot.img"
DIR="/d/桌面/star26-deps/日志"
OUT="$DIR/p15-klog.txt"
RUN="$DIR/p15-run.log"

mkdir -p "$DIR"
: > "$RUN"
rm -f "$OUT"

ts() { date +%H:%M:%S; }
say() { echo "[$(ts)] $*" | tee -a "$RUN"; }

say "adb reboot bootloader"
"$ADB" reboot bootloader >> "$RUN" 2>&1

up=0
for i in $(seq 1 60); do
    sleep 1
    if "$FB" devices 2>/dev/null | grep -q fastboot; then
        say "android fastboot up after ${i}s"
        up=1
        break
    fi
done
[ "$up" = 1 ] || { say "FATAL android fastboot never came up"; exit 2; }

say "fastboot boot p14-boot.img"
"$FB" boot "$IMG" >> "$RUN" 2>&1
say "fastboot boot command returned"

# the kernel needs ~210s before it hands back; probe from 100s on
sleep 100
say "probe window open"

for i in $(seq 1 120); do
    out=$("$FB" getvar product 2>&1)
    if echo "$out" | grep -qi "FAILED\|waiting for"; then
        sleep 4
        continue
    fi
    say "loader answered at probe $i: $(echo "$out" | head -3 | tr '\n' ' ')"
    "$FB" get_staged "D:\\桌面\\star26-deps\\日志\\p15-klog.txt" >> "$RUN" 2>&1
    if [ -s "$OUT" ]; then
        say "GOT $(stat -c%s "$OUT") bytes"
        exit 0
    fi
    say "get_staged produced nothing, retry"
    sleep 2
done

say "timed out without a log"
exit 1
