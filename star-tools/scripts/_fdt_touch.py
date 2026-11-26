import struct, sys

path = sys.argv[1] if len(sys.argv) > 1 else '/root/star26/star-B.dtb'
d = open(path, 'rb').read()
hdr = struct.unpack_from('>10I', d, 0)
magic, totalsize, off_struct, off_strings = hdr[0], hdr[1], hdr[2], hdr[3]
assert magic == 0xd00dfeed

strings = d[off_strings:]
pos = off_struct
stack = []

def s_at(off):
    e = strings.find(b'\x00', off)
    return strings[off:e].decode('utf-8', 'replace')

compat = {}
reg = {}
while True:
    tok = struct.unpack_from('>I', d, pos)[0]
    pos += 4
    if tok == 1:
        e = d.find(b'\x00', pos)
        name = d[pos:e].decode('utf-8', 'replace')
        pos = (e + 4) & ~3
        stack.append(name)
    elif tok == 2:
        stack.pop()
    elif tok == 3:
        ln, nm = struct.unpack_from('>II', d, pos)
        pos += 8
        val = d[pos:pos + ln]
        pos += ln
        pname = s_at(nm)
        full = '/' + '/'.join([x for x in stack if x])
        if pname == 'compatible':
            compat.setdefault(full, []).append(val.replace(b'\x00', b' ').decode('utf-8', 'replace'))
        elif pname == 'reg':
            reg[full] = val.hex()
    elif tok == 4:
        pass
    elif tok == 9:
        break

print('nodes with compatible:', len(compat))

keys = ('touch', 'goodix', 'focal', 'fts', 'novatek', 'himax', 'synaptics', 'digitizer')
hits = []
for full, props in compat.items():
    for p in props:
        low = p.lower()
        if any(k in low for k in keys):
            hits.append((full, p))

for full, p in hits:
    print(full, '->', p, 'reg=', reg.get(full, '?'))

if not hits:
    print('no touch compatible strings; i2c/spi nodes:')
    for full, props in compat.items():
        if 'i2c' in full or 'spi' in full:
            print(full, '->', props[0])
