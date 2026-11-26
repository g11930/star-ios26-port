import re
p='/mnt/c/ios26/s175-log.bin'
d=open(p,'rb').read().decode('utf-8','replace').replace('\0','')
lines=d.split('\n')

def ctx(pattern, label, before=3, after=8, maxhit=4):
    print('\n########## %s ##########' % label)
    hits=0
    for i,l in enumerate(lines):
        if re.search(pattern,l):
            hits+=1
            if hits>maxhit: break
            print('--- hit %d at line %d ---' % (hits,i))
            for j in range(max(0,i-before),min(len(lines),i+after)):
                print('  '+lines[j][:220])
    print('(total hits %d)' % hits)

ctx(r'panic|panicWith|Panic', 'PANIC')
ctx(r'WindowServer', 'WINDOWSERVER')
ctx(r'first_frame|first frame', 'FIRST_FRAME')
ctx(r'default_before=AnnibaleMetalDevice', 'ANNI_METAL_DEFAULT')
ctx(r'sbmetal26|sb26', 'SBMETAL_TRACES', before=0, after=0, maxhit=25)
ctx(r'SecTaskLoadEntitlements|error=22', 'ENTITLE_ERR22')
ctx(r'rc\.jobs|mesa', 'RCJOBS_MESA')

# timeline: first and last timestamped line
ts=re.compile(r'(\d{4}-\d\d-\d\d \d\d:\d\d:\d\d)')
stamps=[(i,m.group(1)) for i,l in enumerate(lines) for m in [ts.search(l)] if m]
print('\n########## TIMELINE ##########')
print('timestamped lines', len(stamps))
if stamps:
    print('first', stamps[0])
    print('last ', stamps[-1])
