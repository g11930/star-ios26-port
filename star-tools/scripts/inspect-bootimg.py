#!/usr/bin/env python3
"""Read-only inspection of an Android boot image carrying a XNUP container.

Prints the boot image header fields and every XNUP entry name/size found in the
gzip-compressed kernel blob. Never modifies the input.
"""
import gzip
import struct
import sys
import zlib
from pathlib import Path


def inspect(path: Path):
    data = path.read_bytes()
    if data[:8] != b'ANDROID!':
        print(f'{path.name}: NOT an Android boot image ({data[:8]!r})')
        return
    kernel_size, kernel_addr = struct.unpack_from('<II', data, 8)
    ramdisk_size, _ = struct.unpack_from('<II', data, 16)
    second_size, _ = struct.unpack_from('<II', data, 24)
    page_size = struct.unpack_from('<I', data, 36)[0]
    header_version = struct.unpack_from('<I', data, 40)[0]
    print(f'{path.name}: {len(data)} B, header_v{header_version}, '
          f'kernel={kernel_size} ramdisk={ramdisk_size} second={second_size} page={page_size}')

    off = page_size
    kernel = data[off:off + kernel_size]
    # kernel = gzip(BootShim + FD + XNUP) + DTB ; decompress ignoring the DTB tail
    d = zlib.decompressobj(16 + zlib.MAX_WBITS)
    try:
        blob = d.decompress(kernel) + d.flush()
    except zlib.error as exc:
        print(f'  gzip decompress failed: {exc}')
        return
    print(f'  blob={len(blob)} B, shim={blob[:176]!r}'[:120])
    at = blob.find(b'XNUP')
    if at < 0:
        print('  NO XNUP container in blob')
        return
    size = struct.unpack_from('<I', blob, at + 4)[0]
    print(f'  XNUP at blob offset {at}, declared size {size}')
    p = at + 8
    end = at + 8 + size
    while p + 24 <= end:
        name, esize, reserved = struct.unpack_from('<16sII', blob, p)
        p += 24
        if name[0] == 0:
            print('  terminator OK' if p == end else f'  BAD terminator at {p}/{end}')
            break
        nm = name.split(b'\0', 1)[0].decode('ascii', 'replace')
        print(f'    entry {nm:16} {esize:>10} B')
        p += (esize + 15) & ~15
    print(f'  container fits in 64 MiB payload window: {size <= 0x04000000}')


if __name__ == '__main__':
    for arg in sys.argv[1:]:
        inspect(Path(arg))
