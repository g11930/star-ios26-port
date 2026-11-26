#!/usr/bin/env python3
"""Verify cache26.dmg: read back every file, compare sha256 with the source."""
import sys, hashlib, os
sys.path.insert(0, '/root/dsc26_zeta_scripts')
import zeta_apfs_image as apfs

img = '/root/cache26.dmg'
with open(img, 'rb') as h:
    c = apfs.Container(h)
    vols = list(c.volumes())
    print('volumes:', [v.name for v in vols])
    v = [x for x in vols if x.name == 'Cache26'][0]
    # enumerate root dir records
    ok = bad = 0
    for key, value in v.records(2, apfs.TYPE_DIR_REC):
        length = struct.unpack_from('<I', key, 8)[0] & 0x3ff if False else None
    # simpler: walk dir records via lookup of each staged name
    stage = '/root/cache26_stage'
    names = sorted(os.listdir(stage))
    import struct
    for name in names:
        ino = v.lookup('/' + name)
        x = v.xattrs(ino)
        if 'com.apple.decmpfs' in x:
            print(f'  {name}: UNEXPECTED decmpfs (compressed)!')
            bad += 1
            continue
        # file size from inode? use extents stream: main data stream
        size, extents = None, None
        # get file size via the inode xattr absence; read via stream_extents of data stream:
        # data stream oid: use records(TYPE_FILE_EXTENT) of the inode's data stream.
        # The zeta reader exposes stream_extents(stream_oid) where stream oid is stored in the inode.
        # Fallback: sum extents of the file via records(ino, TYPE_FILE_EXTENT) -- the data stream
        # shares the inode oid for the default stream in APFS.
        exts = v.records(ino, apfs.TYPE_FILE_EXTENT)
        cursor, total_len = 0, 0
        data = bytearray()
        for k, val in sorted(exts, key=lambda kv: struct.unpack_from('<Q', kv[0], 8)[0]):
            logical, = struct.unpack_from('<Q', k, 8)
            ln_flags, phys, crypto = struct.unpack_from('<QQQ', val)
            ln = ln_flags & 0x00ffffffffffffff
            if crypto:
                print(f'  {name}: encrypted extent'); bad += 1; break
            data += c.read_raw(phys * c.block_size, ln)
            total_len += ln
        src = os.path.join(stage, name)
        want = open(src, 'rb').read()
        if bytes(data) == want:
            ok += 1
        else:
            print(f'  {name}: MISMATCH src={len(want)} read={len(data)}')
            bad += 1
    print(f'RESULT: ok={ok} bad={bad} of {len(names)}')
