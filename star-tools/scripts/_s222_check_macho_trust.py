#!/usr/bin/env python3
"""Check whether plain Mach-O files' original cdhashes are in the Apple trust caches."""
import sys, struct, hashlib
from pathlib import Path

CPU_TYPE_ARM64 = 0x0100000c
LC_CODE_SIGNATURE = 0x1d

def load_cmd_signature(data):
    magic, cputype, subtype, filetype, ncmds, sizeofcmds = struct.unpack_from('<6I', data, 0)
    assert magic == 0xfeedfacf, 'not Mach-O'
    off = 32
    for _ in range(ncmds):
        cmd, cmdsize = struct.unpack_from('<II', data, off)
        if cmd == LC_CODE_SIGNATURE:
            return struct.unpack_from('<I', data, off + 8)[0]
        off += cmdsize
    return None

def code_directory(data):
    sig_off = load_cmd_signature(data)
    if sig_off is None or sig_off >= len(data):
        return None
    magic, length, count = struct.unpack_from('>III', data, sig_off)
    if magic != 0xfade0cc0:
        return None
    best = None
    for i in range(count):
        t, o = struct.unpack_from('>II', data, sig_off + 12 + 8 * i)
        if t == 0x10000:  # CSSLOT_CODEDIRECTORY
            best = sig_off + o
    if best is None:
        return None
    magic2, length2, version, flags, hash_off, ident_off, n_special, n_code = struct.unpack_from('>IIIIIIII', data, best)
    limit = 0 if version < 0x20100 else struct.unpack_from('>I', data, best + 36)[0]
    htype, _, _, _, _, _, _, _ = struct.unpack_from('<BBBBBBBB', data, best + 40)
    if limit == 0:
        limit = hash_off + 32 * (n_special + n_code)
    cdhash = hashlib.sha256(bytes(data[best:best + limit])).hexdigest()
    return cdhash, limit, hash_off, 32 * (n_special + n_code)

def trust_hashes(paths):
    out = set()
    for p in paths:
        blob = Path(p).read_bytes()
        # IM4P -> payload (skip ASN.1): find 'trst'/'trcs' then payload after OCTET STRING
        i = blob.find(b'trst') if b'trst' in blob else blob.find(b'trcs')
        # payload length: parse DER-ish like zeta: 0x30 len ... OCTET STRING
        # simpler: trust cache payload starts right after the IM4P header; find version-2 magic
        # IM4P: 0x30 82 <len> 04 16 <type 4> ... 04 82 <len> <payload>
        # locate OCTET STRING after the type tag
        j = blob.find(b'\x04\x82', i)
        plen = struct.unpack_from('>H', blob, j + 2)[0]
        raw = blob[j + 4:j + 4 + plen]
        count = struct.unpack_from('<I', raw, 20)[0]
        for k in range(count):
            out.add(bytes(raw[24 + 24 * k:44 + 24 * k]))
    return out

def main():
    machos = [Path(p) for p in sys.argv[1].split(',')]
    trusts = trust_hashes(sys.argv[2:])
    for p in machos:
        data = p.read_bytes()
        cd = code_directory(data)
        if cd is None:
            print(f'{p.name}: NO valid CodeDirectory')
            continue
        cdhash, limit, hash_off, nslots = cd
        hit = bytes.fromhex(cdhash)[:20] in trusts
        print(f'{p.name}: size={len(data)} cdhash={cdhash[:40]} slots={nslots} '
              f'{"HIT in trust cache" if hit else "MISS"}')

if __name__ == '__main__':
    main()
