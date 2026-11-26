#!/bin/bash
# P24: clear the one thing softpipe cannot do.
#
# rwa_buffer_create asks for PIPE_BIND_SHARED once a buffer reaches a page, so that freedreno can lay a
# texture over it by handle. softpipe reads that same bit as "this is a display target" and asks its
# winsys for one; null_sw_winsys answers every such request with NULL, so every buffer of 4 KB or more
# fails on the software device. The window server's 1125x2436 framebuffer copy is 11239424 bytes, and
# that is the allocation that failed (P23 log, "null_sw_displaytarget_create() returning NULL").
#
# The shipped library is Mesa 26.2.5, built against the iOS 26 SDK elsewhere; nothing here can rebuild
# it, and it is the only build that is known to compile this iOS's shaders. So the bit is cleared in the
# instruction that sets it: at 0x5658, "csel w8, w9, w8, hi" after "cmp x22, #0xfff" -- replaced with a
# nop, w8 keeps 0x4060 (shader|constant|index buffer) and the shared bit is never added. One
# instruction, same length, so every address in the file stays where it was.
set -e
SRC=/root/star26/release/v0.1.3/hackios-k90-v0.1.3/root/lib/libannibaleair.dylib
OUT=/root/star26/p24
mkdir -p "$OUT"
cp -f "$SRC" "$OUT/libannibaleair.dylib"
L="$OUT/libannibaleair.dylib"

echo "=== prove the signer matches this library before touching it ==="
cp -f "$L" "$OUT/signer-check.dylib"
md5sum "$OUT/signer-check.dylib"
python3 /root/resign-adhoc.py "$OUT/signer-check.dylib" | tail -3
md5sum "$OUT/signer-check.dylib"
if [ "$(md5sum < "$OUT/signer-check.dylib")" = "$(md5sum < "$SRC")" ]; then
	echo "signer reproduces the original byte for byte"
else
	echo "WARNING: signer does not reproduce the original; the signature format differs" >&2
fi
rm -f "$OUT/signer-check.dylib"

echo "=== patch 0x5658 ==="
python3 - "$L" <<'PY'
import sys
p = sys.argv[1]
d = bytearray(open(p, "rb").read())
at = 0x5658
before = d[at:at+4]
print("before:", before.hex())
assert before == bytes.fromhex("2881881a"), "not the csel this patch expects: " + before.hex()
d[at:at+4] = bytes.fromhex("1f2003d5")          # nop
open(p, "wb").write(d)
print("after :", bytes(open(p, "rb").read()[at:at+4]).hex(), "(nop)")
PY

echo "=== disassemble the site ==="
/usr/bin/llvm-objdump --disassemble --start-address=0x5640 --stop-address=0x5680 "$L" 2>/dev/null | tail -14

echo "=== resign ==="
python3 /root/resign-adhoc.py "$L" | tail -3
ls -la "$L"
md5sum "$L"
