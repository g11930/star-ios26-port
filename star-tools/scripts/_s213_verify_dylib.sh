#!/bin/bash
D=/root/star26/hackios-xnu-userland/userland/obj/libannibale-sb26.dylib
echo "=== new unlock strings in dylib ==="
for s in "waiting for CoverSheet" "layout element" "occlusion reasons" "boot unlock done" "unlocking without the lock screen"; do
  c=$(strings "$D" | grep -Fc "$s")
  echo "  [$c] $s"
done
echo "=== arch ==="
python3 - "$D" <<'PY'
import struct,sys
d=open(sys.argv[1],'rb').read()
cpu,sub=struct.unpack_from('<ii',d,4)
print('size=%d cputype=%#x cpusubtype=%#x arm64e=%s' % (len(d),cpu&0xffffffff,sub&0xffffffff,(sub&0xffffffff)==0x80000002))
PY
echo "=== compare old (should lack new strings) ==="
OLD=/root/star26/hackios-xnu-userland/userland/obj/libannibale-sb26.dylib.s213-pre
echo "  old 'waiting for CoverSheet': $(strings "$OLD" | grep -Fc 'waiting for CoverSheet')"
md5sum "$D" "$OLD"
