#!/usr/bin/env python3
"""Definitive check: launchd/dyld cdhash vs Apple trust caches (proper DER parse)."""
import struct, hashlib
from pathlib import Path

def der_elem(blob, at):
    tag = blob[at]
    at += 1
    b = blob[at]; at += 1
    if b < 0x80:
        length = b
    else:
        n = b & 0x7f
        length = int.from_bytes(blob[at:at+n], 'big')
        at += n
    return tag, blob[at:at+length], at + length

def im4p_payload(blob):
    # IM4P: SEQUENCE { OCTETSTRING type, OCTETSTRING payload }
    tag, _, body = der_elem(blob, 0)
    assert tag == 0x30, 'not a SEQUENCE'
    t1, type_val, at = der_elem(blob, body)
    t2, payload, _ = der_elem(blob, at)
    return bytes(type_val), payload

def trust_hashes(paths):
    out = {}
    for p in paths:
        t, raw = im4p_payload(Path(p).read_bytes())
        count = struct.unpack_from('<I', raw, 20)[0]
        entries = {}
        for k in range(count):
            entries[bytes(raw[24+24*k:44+24*k])] = (t, bytes(raw[44+24*k:48+24*k]))
        out[p] = (t, count, entries)
    return out

def macho_cdhash(path):
    data = Path(path).read_bytes()
    magic, ct, st, ft, ncmds, sizeofcmds = struct.unpack_from('<6I', data, 0)
    assert magic == 0xfeedfacf
    off = 32; sig = None
    for _ in range(ncmds):
        cmd, cs = struct.unpack_from('<II', data, off)
        if cmd == 0x1d:
            sig = struct.unpack_from('<I', data, off+8)[0]
        off += cs
    m, length, count = struct.unpack_from('>III', data, sig)
    d = dl = None
    for i in range(count):
        t, o = struct.unpack_from('>II', data, sig+12+8*i)
        bm, bl = struct.unpack_from('>II', data, sig+o)
        if bm == 0xfade0c02:
            d, dl = sig+o, bl
    ver, flags, hoff, ioff, nsp, ncode = struct.unpack_from('>IIIIII', data, d+8)
    limit = struct.unpack_from('>I', data, d+32)[0]
    htype, psize = data[d+37], data[d+39]
    h = hashlib.sha256(bytes(data[d:d+dl])).digest()
    return h[:20], len(data), ncode, psize

def main():
    machos = ['root26:/root/ul26/usr/dyld', 'root26:/root/ul26/usr/launchd']
    import subprocess
    trusts = trust_hashes([sys_arg for sys_arg in __import__('sys').argv[1:]])
    total = 0
    for p, (t, n, entries) in trusts.items():
        print(f'{p}: type={t} entries={n}')
        total += n
    print('total trust entries:', total)
    for name in ('dyld', 'launchd'):
        out = subprocess.run(['python3', '-c', f'''
import sys; sys.path.insert(0, "/root/dsc26_zeta_scripts")
'''], capture_output=True)
    # compute locally via WSL paths is not possible here; caller passes hashes via env
    for line in __import__('os').environ.get('CDHASHES', '').split(','):
        if not line: continue
        name, hexh = line.split('=')
        hh = bytes.fromhex(hexh)
        hit = [(p, t) for p, (t, n, e) in trusts.items() if hh in e]
        print(f'{name}: {"HIT " + str(hit) if hit else "MISS"}')

main()
