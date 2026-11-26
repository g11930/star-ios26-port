#!/bin/bash
NEW=/root/star26/hackios-xnu-userland/userland/obj/libannibale-sb26.dylib
OLD=/root/star26/s111/work/rootbuild/root/lib/libannibale-sb26.dylib
echo "=== arch check ==="
/usr/bin/clang -target arm64-apple-ios16.5 -isysroot /root/theos/sdks/iPhoneOS16.5.sdk -print-target-triple 2>/dev/null || true
python3 - "$NEW" "$OLD" <<'PY'
import struct,sys
for p in sys.argv[1:]:
    d=open(p,'rb').read()
    magic=d[:4]
    # Mach-O 64 = 0xfeedfacf ; cpu subtype arm64e = 0x80000002 (with PTRAUTH ABI bits possibly)
    is64 = magic in (b'\xcf\xfa\xed\xfe', b'\xfe\xed\xfa\xcf')
    print(p.split('/')[-2:], 'size',len(d),'magic',magic.hex(),'mach64',is64)
    if is64:
        cpu,sub=struct.unpack_from('<ii',d,4)
        print('   cputype',hex(cpu & 0xffffffff),'cpusubtype',hex(sub & 0xffffffff),
              'arm64e' if (sub & 0xffffffff)==0x80000002 else '')
PY
echo "=== new iconfill strings ==="
strings "$NEW" | grep -iE "iconfill|AppIcon60x60|sb26 iconview scan" | head -10
echo "=== old md5 / new md5 ==="
md5sum "$NEW" "$OLD"
