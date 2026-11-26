#!/bin/bash
L=/root/star26/p22/libannibalemetal.dylib
LDID=/root/theos/toolchain/linux/iphone/bin/ldid
cp -f "$L" "$L.unsigned"

echo "=== ldid version ==="
"$LDID" -v 2>&1 | head -3

echo "=== sign ==="
"$LDID" -S "$L"
echo "sign exit=$?"

echo "=== size after ==="
ls -la "$L"

echo "=== has SuperBlob? ==="
python3 -c "
import struct
d=open('$L','rb').read()
i=d.find(struct.pack('>I',0xfade0cc0))
print('SuperBlob at', hex(i) if i>=0 else 'NOT FOUND', 'size', len(d))
"
