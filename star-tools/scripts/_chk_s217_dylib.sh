#!/bin/bash
K=/mnt/d/桌面/star26-deps/k90-ref/v021/hackios-k90-v0.2.1/root/lib/libannibale-sb26.dylib
R=/tmp/s217rd/lib/libannibale-sb26.dylib
echo "=== md5: K90 release vs what is in s217 ramdisk ==="
md5sum "$K" "$R" 2>&1
echo
echo "=== which K90 markers does it actually carry ==="
for s in "_appearState" "unlockUIFromSource" "CoverSheet" "boot unlock" "waiting for CoverSheet" "unlock %s" "shouldForceBitmapImages" "software_icons_installed" "activation_installed"; do
  printf "  %-28s %s\n" "$s" "$(grep -a -c "$s" "$R" 2>/dev/null)"
done
echo
echo "=== architecture ==="
python3 - "$R" <<'PY'
import struct, sys
d = open(sys.argv[1], "rb").read()
cpu, sub = struct.unpack_from("<II", d, 4)
print("  size %d  cputype %#x  cpusubtype %#x" % (len(d), cpu, sub))
PY
