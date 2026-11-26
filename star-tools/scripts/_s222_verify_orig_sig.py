#!/usr/bin/env python3
"""Use zeta's exact verify_signature logic on the 3 reconstructed slices as they
exist now. Tells us whether rewrite-zeta-dyld-cache.py will accept them."""
import struct, hashlib, sys
from pathlib import Path

CSMAGIC_EMBEDDED_SIGNATURE = 0xfade0cc0
CSMAGIC_CODEDIRECTORY = 0xfade0c02

def code_directory(data, sig_off, sig_size):
    magic, _, count = struct.unpack_from('>III', data, sig_off)
    if magic != CSMAGIC_EMBEDDED_SIGNATURE:
        raise ValueError('no embedded signature')
    found = []
    for slot in range(count):
        _, at = struct.unpack_from('>II', data, sig_off + 12 + 8 * slot)
        m, length = struct.unpack_from('>II', data, sig_off + at)
        if m == CSMAGIC_CODEDIRECTORY:
            found.append((sig_off + at, length))
    if len(found) != 1:
        raise ValueError(f'{len(found)} CD')
    return found[0]

def verify(data, sig_off, sig_size):
    cd, length = code_directory(data, sig_off, sig_size)
    _, _, hash_off, _, _, slots, limit, _, _, _, page_shift = struct.unpack_from('>IIIIIIIBBBB', data, cd + 8)
    page = 1 << page_shift
    bad = 0
    for i in range(slots):
        stored = bytes(data[cd + hash_off + 32*i:cd + hash_off + 32*(i+1)])
        if hashlib.sha256(data[i*page:min((i+1)*page, limit)]).digest() != stored:
            bad += 1
            if bad <= 3:
                print(f'    bad page {i}')
    return bad, slots, page_shift

DIR = Path(sys.argv[1]) if len(sys.argv) > 1 else Path('/root/dsc26/System/Library/Caches/com.apple.dyld')
for name in ['dyld_shared_cache_arm64e.35.dyldlinkedit',
             'dyld_shared_cache_arm64e.72.dyldlinkedit',
             'dyld_shared_cache_arm64e.83.dyldlinkedit']:
    p = DIR / name
    data = p.read_bytes()
    sig_off, sig_size = struct.unpack_from('<QQ', data, 0x28)
    print(f'=== {name} ===  sig_off={sig_off:#x} sig_size={sig_size:#x}')
    try:
        bad, slots, ps = verify(data, sig_off, sig_size)
        print(f'  VERIFY bad_pages={bad}/{slots} page_shift={ps} -> {"PASS" if bad==0 else "FAIL"}')
    except Exception as e:
        print(f'  VERIFY ERROR: {e}')
