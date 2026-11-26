p = '/root/star26/s111/work/rootbuild/root/etc/rc.jobs'
s = open(p).read()
old = ('/annibale/bin/anntouch wait 300 tap 0.385 0.715\n'
       '/annibale/bin/anntouch wait 420 tap 0.385 0.715')
taps = ' '.join(['wait 20 tap 0.385 0.715'] * 30)
new = '/annibale/bin/anntouch ' + taps
assert old in s
s = s.replace(old, new, 1)
open(p, 'w').write(s)
print([l for l in s.splitlines() if 'anntouch' in l])
