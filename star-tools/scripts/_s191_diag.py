import re
p='/mnt/c/ios26/s191late-log.bin'
d=open(p,'rb').read().decode('utf-8','replace').replace('\0','')
lines=d.split('\n')
print('=== all sb26 lines ===')
for l in lines:
    if 'sb26:' in l:
        print(' ',l.strip()[:200])
print('\n=== icon-related ===')
for l in lines:
    if re.search(r'iconfill|iconview|SBIcon|AppIcon|iconImage', l, re.I):
        print(' ',l.strip()[:200])
print('\n=== timestamp span ===')
ts=re.findall(r'(\d\d:\d\d:\d\d)\.\d+\+0800',d)
print('first',ts[0] if ts else '-', 'last', ts[-1] if ts else '-', 'count', len(ts))
print('\n=== tail 15 ===')
for l in lines[-15:]:
    print(' ',l.strip()[:180])
