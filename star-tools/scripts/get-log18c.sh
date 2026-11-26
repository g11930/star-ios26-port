#!/bin/bash
# Pull the logdump partition (sda24) into C:/ios26/s18c-log.bin and print the
# parts that matter for a checkpointed run: the loader's `result:` line and the
# kernel section that the checkpoint hands back.
# Never run `oem log` first -- in a returned state it calls compose_logs(NULL,0)
# and wipes exactly the section we are reading.
export MSYS_NO_PATHCONV=1
OUT=s18c-log.bin
cd /c/ios26 || exit 1

adb.exe shell "su -c 'dd if=/dev/block/sda24 bs=4096 count=2048 2>/dev/null | base64'" \
	| tr -d '\r\n ' | base64 -d > "$OUT"
ls -la "$OUT"
python3 - "$OUT" <<'PY'
import sys
d = open(sys.argv[1], "rb").read()
t = d.decode("utf-8", "replace").replace("\0", "")
print("total text %d chars" % len(t))
for pat in ("== XNULOADER", "result:", "jumping to", "== KERNEL LOG ==", "STARX", "star: milestone"):
    print("  %-20s %d" % (pat, t.count(pat)))
r = t.find("result:")
print("=== result line ===")
print(t[r:r + 200] if r > 0 else "(none)")
k = t.find("== KERNEL LOG ==")
print("=== kernel section (%d chars) ===" % ((t.find("== END OF LOG ==") - k) if k > 0 else 0))
print(t[k:k + 8000] if k > 0 else "(no marker)")
PY
