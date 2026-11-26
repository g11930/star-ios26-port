#!/bin/bash
# Does the arm64e build actually contain pointer-authentication instructions?
# SM8350 has no FEAT_PAuth; every PAC instruction executed is an undefined-
# instruction trap that sleh.c has to emulate. If the toolchain emitted none,
# the earlier "no PAC" conclusion holds and the early death is something else.
python3 - <<'PY'
import struct

P = '/root/star26/star-native/BUILD/obj/RELEASE_ARM64_BCM2837/mach.release.bcm2837'
d = open(P, 'rb').read()
magic, cputype, cpusub, ft, ncmds, sz, flags, res = struct.unpack_from('<IiiIIIII', d, 0)
blobs = []
off = 32
for _ in range(ncmds):
    cmd, size = struct.unpack_from('<II', d, off)
    if cmd == 0x19:
        name = d[off+8:off+24].split(b'\0', 1)[0].decode()
        fo, fs = struct.unpack_from('<QQ', d, off+40)
        if name in ('__TEXT', '__TEXT_EXEC') and fs:
            blobs.append((name, d[fo:fo+fs]))
    off += size

# exact encodings (mask 0xfffffc1f for the register fields where needed)
EXACT = {
    0xD503237F: 'pacibsp', 0xD503233F: 'paciasp',
    0xD50323FF: 'autibsp', 0xD50323BF: 'autiasp',
    0xD503279F: 'xpaclri',
    0xD65F0FFF: 'retab',   0xD65F0BFF: 'retaa',
}
# braa/blraa/braaz/blraaz: 1101011 0001 1111 0000 1 op Rm Rn
BR = {
    0xD73F0800: 'braa',   0xD73F0C00: 'blraa',
    0xD73F081F: 'braaz',  0xD73F0C1F: 'blraaz',
    0xD73F0A00: 'brab',   0xD73F0E00: 'blrab',
}
for name, b in blobs:
    exact = {}
    br = {}
    for i in range(0, len(b) - 4, 4):
        w = struct.unpack_from('<I', b, i)[0]
        if w in EXACT:
            exact[EXACT[w]] = exact.get(EXACT[w], 0) + 1
        # match branch family: mask out Rn/Rm (bits 5-9, 16-20)
        m = w & 0xFFFFE0E0
        if m in BR:
            br[BR[m]] = br.get(BR[m], 0) + 1
    print('%-12s size %8d  pac %s' % (name, len(b), exact or 'none'))
    print('%-12s               br  %s' % ('', br or 'none'))
PY
