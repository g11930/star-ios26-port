#!/bin/bash
# Finish the arm64e build: mark the pointer-auth ABI in the header, then ad-hoc sign it.
#
# clang 18 builds arm64e objects without the pointer-auth ABI bit, so ld64 emits cpusubtype 2 and
# warns "incompatible arm64e ABI compiler". The shipped library is 0x80000002 (arm64e, ptrauth ABI
# v0) and dyld compares that field when it loads a dylib into an arm64e process, so the field is set
# to match. It also happens that clang emitted no PAC instructions at all here (0 pacibsp, 0 retab),
# which is the lighter path on star: nothing has to go through the kernel's PAC emulation.
set -e
L=/root/star26/p23/libannibalemetal.dylib
LDID=/root/theos/toolchain/linux/iphone/bin/ldid

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
/root/theos/toolchain/linux/iphone/bin/otool -hv "$L" | sed -n '2,5p'
strings "$L" | grep -c 'client-memory copy allocation failed'
