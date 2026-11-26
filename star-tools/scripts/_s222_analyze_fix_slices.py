#!/usr/bin/env python3
"""Analyze the 3 reconstructed .dyldlinkedit slices: where zero-fill happened
and whether it overlaps the code-signature region hashed by CodeDirectory.
"""
import struct
import hashlib
from pathlib import Path

FIX = Path(r'D:/桌面/star26-deps/work/zeta_scripts')  # unused
DIR = None
import sys
DIR = Path(sys.argv[1]) if len(sys.argv) > 1 else Path(r'/root/dsc26/System/Library/Caches/com.apple.dyld')

CSMAGIC_EMBEDDED_SIGNATURE = 0xfade0cc0
CSMAGIC_CODEDIRECTORY = 0xfade0c02
HEADER_SIGNATURE_OFF = 0x28

for name in ['dyld_shared_cache_arm64e.35.dyldlinkedit',
             'dyld_shared_cache_arm64e.72.dyldlinkedit',
             'dyld_shared_cache_arm64e.83.dyldlinkedit']:
    p = DIR / name
    if not p.exists():
        print(name, 'MISSING')
        continue
    data = p.read_bytes()
    print(f'\n=== {name} size={len(data)} ===')
    print(' magic head:', data[:16])
    sig_off, sig_size = struct.unpack_from('<QQ', data, HEADER_SIGNATURE_OFF)
    print(f' sig_off={sig_off:#x} sig_size={sig_size:#x} (file {len(data):#x})')
    # find trailing zero run
    z = len(data)
    while z > 0 and data[z - 1] == 0:
        z -= 1
    print(f' trailing zero run: {len(data) - z} bytes (from {z:#x} to {len(data):#x})')
    # signature region sanity
    if sig_off and sig_off + sig_size <= len(data):
        sig = data[sig_off:sig_off + sig_size]
        magic, _, count = struct.unpack_from('>III', sig, 0)
        print(f' sig magic={magic:#x} count={count} ok={magic == CSMAGIC_EMBEDDED_SIGNATURE}')
        # is the signature region itself zero?
        print(f' sig region all zero? {all(b == 0 for b in sig[:64])}')
        zero_in_sig = sum(1 for b in sig if b == 0)
        print(f' sig zero bytes: {zero_in_sig}/{len(sig)}')
    # where does the trailing zero start relative to sig_off
    if sig_off:
        print(f' trailing-zero starts {"AFTER" if z >= sig_off else "BEFORE"} sig_off (delta {z - sig_off:+#x})')
