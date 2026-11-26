#!/usr/bin/env python3
"""Extract small files from a remote IPSW (zip) with HTTP Range requests.

No need to download the whole multi-GB archive: read the EOCD/central directory
from the tail, then fetch only the chosen members' local file headers + data.

Usage:
  ipsw_range_extract.py list
  ipsw_range_extract.py get <name-substring> <output-path>
"""
import os
import struct
import sys
import urllib.request
import zlib

URL = ("https://updates.cdn-apple.com/2026SummerFCS/"
       "c2f9fa07-0acc-4038-99f4-d7a4b1ac9c06/"
       "iPhone18,3_26.6.2_23G90_Restore.ipsw")
SIZE = 11481186987

EOCD_SIG = 0x06054b50
CD_SIG = 0x02014b50
LFH_SIG = 0x04034b50
Z64_EOCD_SIG = 0x06064b50
Z64_LOC_SIG = 0x07064b50


def range_get(start, length):
    end = start + length - 1
    if end >= SIZE:
        end = SIZE - 1
        length = end - start + 1
    req = urllib.request.Request(URL, headers={
        'Range': f'bytes={start}-{end}',
        'User-Agent': 'Mozilla/5.0',
    })
    with urllib.request.urlopen(req, timeout=120) as r:
        data = r.read()
    if len(data) != length:
        raise RuntimeError(f'short range read: got {len(data)}, want {length}')
    return data


def central_directory():
    tail_len = 1 << 20
    tail = range_get(SIZE - tail_len, tail_len)
    eocd = tail.rfind(b'PK\x05\x06')
    if eocd < 0:
        raise RuntimeError('EOCD not found')
    sig, disk, cd_disk, n_disk, n_total, cd_size, cd_off, comment = struct.unpack_from(
        '<IHHHHIIH', tail, eocd)
    if sig != EOCD_SIG:
        raise RuntimeError('bad EOCD signature')
    if (cd_off == 0xffffffff or cd_size == 0xffffffff or n_total == 0xffff):
        loc = eocd - 20
        lsig, ldisk, z64_off, ndisks = struct.unpack_from('<IIQI', tail, loc)
        if lsig != Z64_LOC_SIG:
            raise RuntimeError('ZIP64 locator not found')
        z64 = range_get(z64_off, 56)
        zsig, zsize, vmade, vneed, zdisk, zcd_disk, zn_disk, zn_total, zcd_size, zcd_off = \
            struct.unpack_from('<IQHHIIQQQQ', z64, 0)
        if zsig != Z64_EOCD_SIG:
            raise RuntimeError('bad ZIP64 EOCD signature')
        n_total, cd_size, cd_off = zn_total, zcd_size, zcd_off
    print(f'entries={n_total} cd_offset={cd_off} cd_size={cd_size}', file=sys.stderr)
    blob = range_get(cd_off, cd_size)
    entries = []
    pos = 0
    while pos + 46 <= len(blob):
        sig, vmade, vneed, flags, method, mtime, mdate, crc, csize, usize, \
            nlen, elen, clen, dstart, iattr, eattr, loff = struct.unpack_from(
                '<IHHHHHHIIIHHHHHII', blob, pos)
        if sig != CD_SIG:
            break
        name_raw = blob[pos + 46:pos + 46 + nlen]
        name = name_raw.decode('utf-8', 'replace')
        extra = blob[pos + 46 + nlen:pos + 46 + nlen + elen]
        # ZIP64 extra field (0x0001) overrides 32-bit sizes/offsets.
        p = 0
        while p + 4 <= len(extra):
            tag, sz = struct.unpack_from('<HH', extra, p)
            body = extra[p + 4:p + 4 + sz]
            if tag == 0x0001:
                q = 0
                if usize == 0xffffffff:
                    usize = struct.unpack_from('<Q', body, q)[0]; q += 8
                if csize == 0xffffffff:
                    csize = struct.unpack_from('<Q', body, q)[0]; q += 8
                if loff == 0xffffffff:
                    loff = struct.unpack_from('<Q', body, q)[0]; q += 8
            p += 4 + sz
        entries.append(dict(name=name, method=method, csize=csize, usize=usize,
                            loff=loff, crc=crc, flags=flags))
        pos += 46 + nlen + elen + clen
    return entries


def extract(entry, out_path):
    lfh = range_get(entry['loff'], 30)
    sig, ver, flags, method, mtime, mdate, crc, csize, usize, nlen, elen = \
        struct.unpack_from('<IHHHHHIIIHH', lfh, 0)
    if sig != LFH_SIG:
        raise RuntimeError('bad local file header')
    data_start = entry['loff'] + 30 + nlen + elen
    blob = range_get(data_start, entry['csize'])
    if method == 0:
        data = blob
    elif method == 8:
        data = zlib.decompress(blob, -15)
    else:
        raise RuntimeError(f'unsupported compression method {method}')
    if len(data) != entry['usize']:
        raise RuntimeError(f'size mismatch: {len(data)} != {entry["usize"]}')
    with open(out_path, 'wb') as f:
        f.write(data)
    return len(data)


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        return 2
    entries = central_directory()
    if sys.argv[1] in ('list', 'all'):
        for e in entries:
            low = e['name'].lower()
            if (sys.argv[1] == 'all' or 'trust' in low or 'im4p' in low or 'cryptex' in low):
                print(f"{e['name']}\t{e['usize']}\tmethod={e['method']}\tloff={e['loff']}")
        print(f'-- total entries: {len(entries)}', file=sys.stderr)
        return 0
    if sys.argv[1] == 'get':
        needle, out = sys.argv[2], sys.argv[3]
        matches = [e for e in entries if needle.lower() in e['name'].lower()]
        if not matches:
            print(f'no member matching {needle!r}', file=sys.stderr)
            return 2
        for e in matches:
            print(f'extracting {e["name"]} ({e["usize"]} B) -> {out}', file=sys.stderr)
            n = extract(e, out)
            print(f'wrote {n} B to {out}')
        return 0
    print(__doc__)
    return 2


if __name__ == '__main__':
    sys.exit(main())
