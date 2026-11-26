#!/bin/bash
# Two read-only probes:
#  1) the panic buffer that loader_panic_sync_ufs() writes to darwin_var + 64 MiB
#     (sda37 starts at GPT block 56044032; 64 MiB in = +16384 blocks of 4096)
#  2) the loader's milestone/percentage table, to learn what 28% means
export MSYS_NO_PATHCONV=1
cd /c/ios26 || exit 1
echo "=== 1. darwin_var + 64 MiB (panic sync area), 1 MiB ==="
adb.exe shell "su -c 'dd if=/dev/block/sda37 bs=4096 skip=16384 count=256 2>/dev/null | base64'" \
	| tr -d '\r\n ' | base64 -d > s17-panic.bin
ls -la s17-panic.bin
python3 - <<'PY'
d = open("s17-panic.bin", "rb").read()
t = d.decode("utf-8", "replace").replace("\0", "")
import re
print("non-zero bytes:", sum(1 for b in d if b), "of", len(d))
for pat in ("STARX", "PANIC", "FAULT", "star: milestone", "KLOG"):
    print("  %-16s %d" % (pat, t.count(pat)))
m = t.find("STARX")
print("--- first 2500 chars that look like text ---")
print("".join(ch if 32 <= ord(ch) < 127 or ch == "\n" else "." for ch in t[:2500]))
PY
