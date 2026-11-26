#!/usr/bin/env python3
"""List the XNUP payload entries inside a resealed boot image, with per-entry md5.

The payload sits somewhere inside p2-boot.img after reseal-loader-img.py, so the
parser scans for the magic instead of assuming an offset.
"""
import hashlib
import struct
import sys
import zlib


def find_xnup(data):
    """Return the XNUP container bytes, decompressing the boot image kernel stream if needed.

    The resealed image is an Android boot image whose kernel segment is a zlib stream
    (gzip wrapper, level 9); the XNUP container lives inside it.
    """
    off = data.find(b'XNUP')
    if off >= 0:
        return data[off:]
    pos = data.find(b'\x1f\x8b\x08')
    while pos >= 0:
        try:
            d = zlib.decompressobj(31)
            blob = d.decompress(data[pos:]) + d.flush()
        except Exception:
            blob = b''
        i = blob.find(b'XNUP')
        if i >= 0:
            return blob[i:]
        pos = data.find(b'\x1f\x8b\x08', pos + 1)
    return None


def entries(path):
    raw = open(path, 'rb').read()
    data = find_xnup(raw)
    if data is None:
        return None, []
    total = struct.unpack_from('<I', data, 4)[0]
    p = 8
    end = p + total
    out = []
    while p + 24 <= end:
        name = data[p:p + 16].split(b'\0', 1)[0].decode('ascii', 'replace')
        size, _res = struct.unpack_from('<II', data, p + 16)
        p += 24
        if not name:
            break
        blob = data[p:p + size]
        out.append({
            'name': name,
            'size': size,
            'md5': hashlib.md5(blob).hexdigest(),
            'data': blob,
        })
        p += (size + 15) // 16 * 16
    return 0, out


def main():
    want = sys.argv[1]
    dump = sys.argv[2] if len(sys.argv) > 2 else None
    off, ents = entries(want)
    if off is None:
        print(f'{want}: no XNUP payload')
        return 1
    print(f'{want}: payload at 0x{off:x}, {len(ents)} entries')
    for e in ents:
        print(f'  {e["name"]:<10} {e["size"]:>10}  {e["md5"]}')
        if dump and e['name'] == dump:
            out = f'/tmp/{dump}.bin'
            open(out, 'wb').write(e['data'])
            print(f'    dumped -> {out}')
        if e['name'] == 'cmdline':
            txt = e['data'].split(b'\0', 1)[0].decode('utf-8', 'replace')
            print(f'    cmdline: {txt}')
    return 0


if __name__ == '__main__':
    sys.exit(main())
