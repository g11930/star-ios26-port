import re
d=open('/mnt/c/ios26/s192now-log.bin','rb').read().decode('utf-8','replace').replace('\0','')
print('log bytes', len(d))
# search anywhere for iconfill with context
for kw in ['iconfill','sb26: icon','filled=','noimg','AppIcon']:
    hits=[l.strip() for l in d.split('\n') if kw in l]
    print('=== %s : %d ===' % (kw,len(hits)))
    for h in hits[:6]: print(' ',h[:200])
# check stderr of SpringBoard may be routed differently; count user-level icon logs
print('\n=== general state ===')
for k in ['error=22','PANIC','KERNEL FAULT','NOT_CODESIGNED','SpringBoard[33]']:
    print('  %-20s %d' % (k, d.count(k)))
ts=re.findall(r'(\d\d:\d\d:\d\d)\.\d+\+0800',d)
print('  ts span', ts[0] if ts else '-', '->', ts[-1] if ts else '-')
