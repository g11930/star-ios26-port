p = '/root/star26/s111/work/rootbuild/root/etc/rc.jobs'
lines = open(p).read().splitlines()
out = []
for l in lines:
    if l.startswith('/annibale/bin/anntouch wait 20 tap'):
        out.extend(['/annibale/bin/anntouch wait 20 tap 0.385 0.715'] * 30)
    else:
        out.append(l)
open(p, 'w').write('\n'.join(out) + '\n')
print('\n'.join(out))
