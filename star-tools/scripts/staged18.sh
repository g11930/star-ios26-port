#!/bin/bash
# In the loader's own Fastboot debug mode: product reads `xnuloader` and the
# staged log is what it wrote on the checkpoint return.  `oem log` must not be
# used here -- it recomposes from the live state and wipes the staged bytes.
export MSYS_NO_PATHCONV=1
cd /c/ios26 || exit 1
F=fastboot.exe
echo "--- product"
timeout 10 "$F" getvar product 2>&1 | tr -d '\r' | grep -i product
echo "--- get_staged"
timeout 60 "$F" -s xnuloader get_staged "$1" 2>&1 | tr -d '\r' | tail -5
ls -la "$1"
python3 - "$1" <<'PY'
import sys
d = open(sys.argv[1], "rb").read()
t = d.decode("utf-8", "replace").replace("\0", "")
print("text %d chars" % len(t))
for pat in ("result:", "== KERNEL LOG ==", "STARX", "star: milestone"):
    print("  %-20s %d" % (pat, t.count(pat)))
i = t.find("result: checkpoint")
print("=== result ===")
print(t[i:i+120] if i > 0 else "(no checkpoint result)")
k = t.find("== KERNEL LOG ==")
print("=== kernel section ===")
print(t[k:k+4000] if k > 0 else "(no marker)")
PY
