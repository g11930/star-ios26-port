#!/bin/bash
# Pull the logdump partition (sda24) into C:/ios26/s17-log.bin, then print the
# part that matters.  Never run `oem log` first: with the loader in a returned
# state that command calls compose_logs(NULL, 0) and wipes the kernel section we
# are trying to read.  dd from Android is the only reliable path.
export MSYS_NO_PATHCONV=1
OUT=s17-log.bin
cd /c/ios26 || exit 1

adb.exe shell "su -c 'dd if=/dev/block/sda24 bs=4096 count=2048 2>/dev/null | base64'" \
	| tr -d '\r\n ' | base64 -d > "$OUT"
ls -la "$OUT"
python3 - "$OUT" <<'PY'
import sys
d = open(sys.argv[1], "rb").read()
t = d.decode("utf-8", "replace").replace("\0", "")
i = t.find("jumping to")
k = t.find("== KERNEL LOG ==")
print("=== tail of the loader section ===")
print(t[max(0, i - 400):i + 200] if i > 0 else t[-1200:])
print("=== kernel section (%d bytes after the marker) ===" % (len(t) - k if k > 0 else 0))
print(t[k:k + 6000] if k > 0 else "(no marker)")
PY
