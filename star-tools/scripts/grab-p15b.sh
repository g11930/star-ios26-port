#!/bin/bash
# P15b: the payload is already running. Wait for the v3 loader to take USB back
# (fallback mode), then pull the staged klog. All paths ASCII: the Chinese ones
# get mangled by the Windows CLI argument conversion.
export MSYS_NO_PATHCONV=1

FB="/d/桌面/adb-fastboot/fastboot.exe"
W="/c/ios26"
OUT="$W/p15-klog.txt"
RUN="$W/p15b-run.log"

: > "$RUN"
rm -f "$OUT"
say() { echo "[$(date +%H:%M:%S)] $*" | tee -a "$RUN"; }

say "waiting for the loader to take USB back (~150s left of kernel time)"
sleep 150
say "probe loop starts"

for i in $(seq 1 90); do
    # Android's bootloader answers getvar result with FAILED; the loader answers with a value
    r=$("$FB" getvar result 2>&1)
    if echo "$r" | grep -qi "FAILED\|waiting for\|no link"; then
        sleep 4
        continue
    fi
    say "LOADER IS BACK at probe $i :: $(echo "$r" | head -2 | tr '\n' ' ')"

    say "oem screenshot"
    "$FB" oem getvar screen >> "$RUN" 2>&1
    "$FB" oem screenshot >> "$RUN" 2>&1

    say "get_staged"
    "$FB" get_staged "$W/p15-klog.txt" >> "$RUN" 2>&1
    if [ -s "$OUT" ]; then
        say "GOT $(stat -c%s "$OUT") bytes"
        sync
        exit 0
    fi
    say "staged empty, retry"
    sleep 3
done

say "no log captured"
exit 1
