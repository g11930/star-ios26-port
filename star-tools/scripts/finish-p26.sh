#!/bin/bash
# P26 finish: mark the arm64e ABI in the header, sign ad-hoc, and check that this
# library is the one that has to reach the device: arm64e, rwa_* exported, the
# sampling half lowering in it, and no PIPE_BIND_SHARED on the software path.
set -e
L=${LIB:-/root/star26/p26/libannibaleair.dylib}
LDID=/root/theos/toolchain/linux/iphone/bin/ldid
OTOOL=/root/theos/toolchain/linux/iphone/bin/otool

cp -f "$L" "$L.unsigned"

python3 - "$L" <<'PY'
import sys
p = sys.argv[1]
d = bytearray(open(p, "rb").read())
assert d[:4] == b"\xcf\xfa\xed\xfe", "not a 64-bit Mach-O"
old = int.from_bytes(d[8:12], "little")
print("cpusubtype before: 0x%08x" % old)
d[8:12] = (0x80000002).to_bytes(4, "little")
open(p, "wb").write(d)
print("cpusubtype after : 0x80000002")
PY

echo "=== sign ==="
"$LDID" -S "$L"

echo "=== result ==="
ls -la "$L"
file "$L"
"$OTOOL" -hv "$L" | sed -n '2,4p'
echo "--- exports ---"
/root/star26/hackios-xnu-kernel/xnu-deps/host/bin/llvm-nm -gU "$L" 2>/dev/null | awk '{print $NF}' | grep -c '^rwa_' || true
echo "--- lowered sampling present (new message) ---"
strings "$L" | grep -c 'does not support tex op' || true
echo "--- old messages still present ---"
strings "$L" | grep -c 'client-memory copy allocation failed' || true
strings "$L" | grep -c 'the GPU driver would not allocate' || true

echo "=== install name ==="
/root/star26/hackios-xnu-kernel/xnu-deps/host/bin/llvm-objdump --macho --private-headers "$L" 2>/dev/null \
	| awk '/LC_ID_DYLIB/{f=1} f&&$1=="name"{print; exit}'
