import struct, sys
p = sys.argv[1]
d = open(p,'rb').read()
magic, total, off_struct, off_strings, off_rsv, ver, lcv, cpu, sz_str, sz_struct = struct.unpack_from('>10I', d, 0)
strs = d[off_strings:off_strings+sz_str]
def name_at(o):
    e = strs.find(b'\x00', o); return strs[o:e].decode('utf8','replace')

pos = off_struct
depth = 0
path = []
first = []
cur = None
props = []
while True:
    t = struct.unpack_from('>I', d, pos)[0]; pos += 4
    if t == 1:  # begin node
        e = d.find(b'\x00', pos)
        nm = d[pos:e].decode('utf8','replace')
        pos = (e+4) & ~3
        path.append(nm); depth += 1
        if len(first) < 6: first.append('/'+'/'.join(path))
    elif t == 2:
        if path and depth: path.pop()
        depth -= 1
    elif t == 3:
        ln, no = struct.unpack_from('>II', d, pos); pos += 8
        data = d[pos:pos+ln]; pos += ln
        pname = name_at(no)
        full = '/'+'/'.join(path)
        if 'fts' in full or pname in ('reg','compatible','interrupts','spi-max-frequency') and 'fts' in full:
            props.append((full, pname, data))
        if 'fts' in full and pname == 'reg':
            print(full, 'reg=', data.hex())
    elif t == 4:
        pass
    elif t == 9:
        break
    else:
        print('unknown token', t, 'at', pos); break
print('first nodes:', first)
for full, pname, data in props[:12]:
    print(full, pname, data[:40])
