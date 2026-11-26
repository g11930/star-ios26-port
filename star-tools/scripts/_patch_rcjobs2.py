p = '/root/star26/s111/work/rootbuild/root/etc/rc.jobs'
s = open(p).read()
old = '/annibale/bin/anntouch wait 45 tap 0.5 0.5 wait 4 tap 0.5 0.5'
new = ('/annibale/bin/anntouch wait 300 tap 0.385 0.715\n'
       '/annibale/bin/anntouch wait 420 tap 0.385 0.715')
assert old in s
s = s.replace(old, new, 1)
open(p, 'w').write(s)
print([l for l in s.splitlines() if 'anntouch' in l])
