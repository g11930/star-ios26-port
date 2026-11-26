#!/usr/bin/env python3
"""Check whether our dyld cache files' original cdhash values are present in the
two Apple trust caches. Pure stdlib. Mirrors rewrite-zeta-dyld-cache.py cdhash.
usage: _s222_check_cdhash_trust.py <cache_dir> <trust_static> <trust_cryptex>
"""
import hashlib
import struct
import sys
from pathlib import Path

CACHE_DIR = Path(sys.argv[1])
TRUST = [sys.argv[2], sys.argv[3]]
HEADER_SIGNATURE_OFF = 0x28
CSMAGIC_EMBEDDED_SIGNATURE = 0xfade0cc0
CSMAGIC_CODEDIRECTORY = 0xfade0c02


def im4p_payload(blob):
    def element(at):
        tag, length = blob[at], blob[at + 1]
        at += 2
        if length & 0x80:
            count = length & 0x7f
            length, at = int.from_bytes(blob[at:at + count], 'big'), at + count
        return tag, at, length
    tag, at, length = element(0)
    items, end = [], at + length
    while at < end:
        tag, start, length = element(at)
        items.append((tag, blob[start:start + length]))
        at = start + length
    return items[1][1].decode(), items[3][1]


def trust_entries(blob):
    kind, payload = im4p_payload(blob)
    version, count = struct.unpack_from('<I', payload)[0], struct.unpack_from('<I', payload, 20)[0]
    return kind, {payload[24 + 24 * i:44 + 24 * i]: payload[44 + 24 * i:48 + 24 * i]
                  for i in range(count)}


def file_cdhash(data):
    magic, _, count = struct.unpack_from('>III', data, 0)
    if magic != CSMAGIC_EMBEDDED_SIGNATURE:
        return None
    found = []
    for slot in range(count):
        _, at = struct.unpack_from('>II', data, 12 + 8 * slot)
        m, length = struct.unpack_from('>II', data, at)
        if m == CSMAGIC_CODEDIRECTORY:
            found.append((at, length))
    if len(found) != 1:
        return None
    cd, length = found[0]
    _, _, hash_off, _, _, slots, limit, hsize, htype, _, page_shift = struct.unpack_from(
        '>IIIIIIIBBBB', data, cd + 8)
    return hashlib.sha256(bytes(data[cd:cd + length])).hexdigest()[:40], page_shift


def main():
    trusted = {}
    for t in TRUST:
        kind, e = trust_entries(Path(t).read_bytes())
        print(f'trust {kind}: {len(e)} entries')
        trusted.update(e)
    print(f'total trusted cdhash: {len(trusted)}')

    names = sorted(CACHE_DIR.glob('dyld_shared_cache_arm64e*'))
    print(f'cache candidate files: {len(names)}')
    hit, miss, skipped = 0, 0, []
    miss_names = []
    for p in names:
        if p.stat().st_size < 0x1000:
            skipped.append((p.name, 'small'))
            continue
        try:
            with open(p, 'rb') as f:
                head = f.read(0x200)
                if not head.startswith(b'dyld_v1'):
                    skipped.append((p.name, 'no magic'))
                    continue
                sig_off, sig_size = struct.unpack_from('<QQ', head, HEADER_SIGNATURE_OFF)
                if sig_off == 0 or sig_size == 0 or sig_off + sig_size > p.stat().st_size:
                    skipped.append((p.name, f'bad sig off={sig_off} size={sig_size}'))
                    continue
                f.seek(sig_off)
                data = f.read(sig_size)
            res = file_cdhash(data)
            if res is None:
                skipped.append((p.name, 'no CD'))
                continue
            cdhash, page_shift = res
            if bytes.fromhex(cdhash) in trusted:
                hit += 1
            else:
                miss += 1
                miss_names.append((p.name, cdhash, page_shift))
        except Exception as ex:
            skipped.append((p.name, f'{type(ex).__name__}: {ex}'))
    print(f'RESULT hit={hit} miss={miss} skipped={len(skipped)}')
    for n, h, ps in miss_names:
        print('  MISS', n, h, 'page_shift', ps)
    print('--- skipped ---')
    for n, why in skipped[:40]:
        print('  SKIP', n, why)


if __name__ == '__main__':
    main()
