#!/usr/bin/env python3
import struct, sys, random, os
sys.path.insert(0, '/root/dsc26_zeta_scripts')
import zeta_apfs_image as apfs

for path in sys.argv[1:]:
    total = os.path.getsize(path) // 4096
    f = open(path, 'rb')
    random.seed(11)
    ok = bad = 0
    for i in random.sample(range(total), 2000):
        f.seek(i * 4096)
        b = f.read(4096)
        if len(b) < 4096:
            continue
        oid, xid = struct.unpack_from('<QQ', b, 8)
        tflag, = struct.unpack_from('<I', b, 24)
        t = tflag & 0xffff
        if oid == 0 or xid == 0 or not (1 <= t <= 30):
            continue  # not an APFS object block
        stored = struct.unpack_from('<Q', b)[0]
        if stored == apfs.fletcher64(b):
            ok += 1
        else:
            bad += 1
            if bad <= 3:
                print(f'  mismatch block {i}: type={t} oid={oid:#x} xid={xid:#x}')
    print(f'{os.path.basename(path)}: APFS-object blocks match {ok}/{ok+bad}')
