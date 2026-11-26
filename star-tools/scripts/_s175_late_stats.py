import re, os

def load(p):
    return open(p,'rb').read().decode('utf-8','replace').replace('\0','')

for name in ['s175-log.bin','s175-late-log.bin','s173d-live.bin']:
    p='/mnt/c/ios26/'+name
    if not os.path.exists(p):
        print(name,'MISSING'); continue
    d=load(p)
    print('\n========== %s (%d bytes) ==========' % (name,len(d)))
    keys=['error=22','cs_flags=26000000','NOT_CODESIGNED',
          'registration failed','backend mismatch',
          'SpringBoard','backboardd','first_frame','first frame',
          'panel swap','surface swap','WindowServer',
          'KERNEL FAULT','PANIC','kalloc_type_view',
          'SpringBoard.33','SB + boot','backlight-on']
    for k in keys:
        print('  %-24s %d' % (k,d.count(k)))
    # last timestamp
    ts=re.findall(r'\d{4}-\d\d-\d\d \d\d:\d\d:\d\d',d)
    print('  last timestamp:', ts[-1] if ts else 'none')
    # kalloc panic context
    m=re.search(r'kalloc_type_view.{0,120}',d)
    if m: print('  kalloc hit:', m.group(0)[:140])
