#!/usr/bin/env python3
p = '/root/star26/s111/work/rootbuild/root/etc/rc.jobs'
s = open(p).read()
if 'MESA_SHADER_CACHE_DIR' in s:
    print('already set'); raise SystemExit

dir = '/var/mobile/Library/Caches/mesa-annibale'
words = ' '.join('%s:MESA_SHADER_CACHE_DIR=%s' % (name, dir) for name in
                 ('SpringBoard', 'backboardd', 'iconservicesagent'))
s = s.replace('/annibale/bin/trialwake',
              '/annibale/bin/annsh setenv ' + words + '\n/annibale/bin/annsh restart SpringBoard\n/annibale/bin/trialwake', 1)
open(p, 'w').write(s)
print(s)