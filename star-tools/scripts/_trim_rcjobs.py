#!/usr/bin/env python3
p = '/root/star26/s111/work/rootbuild/root/etc/rc.jobs'
src = open(p).read()
backup = p + '.s171'
open(backup, 'w').write(src)

lines = src.splitlines()
keep = []
for line in lines:
    s = line.strip()
    if s.startswith('/annibale/bin/anntouch'):
        continue          # the 30 scripted taps and the 200 s wait: they kept SpringBoard busy
    if s.startswith('#') and 'Order matters' in s:
        keep.append(line)
        continue
    keep.append(line)

out = '\n'.join(keep).rstrip('\n') + '\n'
open(p, 'w').write(out)
print('removed', len(lines) - len(out.splitlines()), 'lines')
print(out)
