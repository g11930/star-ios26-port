import re
for name,p in [('s192','/mnt/c/ios26/s192now-log.bin'),('s194','/mnt/c/ios26/s194-win-10.bin')]:
    d=open(p,'rb').read().decode('utf-8','replace').replace('\0','')
    lines=[l for l in d.split('\n') if l.strip()]
    print('==========',name,len(lines),'lines ==========')
    for i,l in enumerate(lines):
        if 'ignite() returned' in l:
            print('ignite at',i,'/',len(lines))
            for j in range(max(0,i-8),min(len(lines),i+8)):
                print('  ',lines[j][:180])
            break
    # where does log end / last timestamp
    ts=re.findall(r'(\d\d:\d\d:\d\d)\.\d+\+0800',d)
    print('last ts', ts[-1] if ts else '-')
    print()
