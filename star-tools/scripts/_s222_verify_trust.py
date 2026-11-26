import struct
import hashlib
from pathlib import Path

# Inlined verbatim from zeta's rewrite-zeta-userland.py (no capstone needed).
def im4p_payload(blob):
    def element(at):
        tag, length = blob[at], blob[at + 1]
        at += 2
        if length & 0x80:
            count = length & 0x7f
            length, at = int.from_bytes(blob[at:at + count], 'big'), at + count
        return tag, at, length
    tag, at, length = element(0)
    assert tag == 0x30, 'IM4P is not a DER sequence'
    items, end = [], at + length
    while at < end:
        tag, start, length = element(at)
        items.append((tag, blob[start:start + length]))
        at = start + length
    assert len(items) >= 4 and items[0][1] == b'IM4P', 'not an IM4P'
    return items[1][1].decode(), items[3][1]

def trust_cache_entries(raw):
    version, count = struct.unpack_from('<I', raw)[0], struct.unpack_from('<I', raw, 20)[0]
    assert version == 2 and len(raw) == 24 + 24 * count, f'not v2 trust cache (v={version} n={count} len={len(raw)} want={24+24*count})'
    return {raw[24 + 24 * i:44 + 24 * i]: raw[44 + 24 * i:48 + 24 * i] for i in range(count)}

for path in [r'D:/桌面/star26-deps/work/trust_static.im4p',
             r'D:/桌面/star26-deps/work/trust_systemcrytex.im4p']:
    blob = Path(path).read_bytes()
    print('FILE', Path(path).name, len(blob), 'sha256', hashlib.sha256(blob).hexdigest()[:16])
    print(' head', blob[:32].hex())
    try:
        kind, payload = im4p_payload(blob)
        entries = trust_cache_entries(payload)
        print(f' KIND={kind!r} payload_len={len(payload)} entries={len(entries)}')
        for cdhash, attr in list(entries.items())[:3]:
            print('  ', cdhash.hex()[:16], list(attr))
    except Exception as e:
        print(' PARSE FAIL:', type(e).__name__, e)
