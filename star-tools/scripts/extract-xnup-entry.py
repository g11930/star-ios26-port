#!/usr/bin/env python3
"""Read-only extractor: pull one named entry out of the XNUP container in an
Android boot image and write it to a file.

usage: extract-xnup-entry.py BOOT.img ENTRY_NAME OUTPUT.bin
"""
import struct
import sys
import zlib
from pathlib import Path


def container_of(path: Path):
    data = path.read_bytes()
    if data[:8] != b'ANDROID!':
        sys.exit(f'{path}: not an Android boot image')
    ksz = struct.unpack_from('<I', data, 8)[0]
    page = struct.unpack_from('<I', data, 36)[0]
    stream = zlib.decompressobj(31)
    blob = stream.decompress(data[page:page + ksz])
    at = blob.find(b'XNUP')
    if at < 0:
        sys.exit(f'{path}: no XNUP container')
    size = struct.unpack_from('<I', blob, at + 4)[0]
    return blob[at:at + 8 + size]


def main():
    if len(sys.argv) != 4:
        sys.exit(__doc__)
    boot, want, out = Path(sys.argv[1]), sys.argv[2].encode(), Path(sys.argv[3])
    c = container_of(boot)
    p, end = 8, len(c)
    while p + 24 <= end:
        name, size, _ = struct.unpack_from('<16sII', c, p)
        p += 24
        if name[0] == 0:
            break
        payload = c[p:p + size]
        if name.split(b'\0', 1)[0] == want:
            out.write_bytes(payload)
            print(f'extracted {want.decode()} {len(payload)} B -> {out}')
            return
        p += (size + 15) & ~15
    sys.exit(f'entry {want.decode()} not found')


if __name__ == '__main__':
    main()
