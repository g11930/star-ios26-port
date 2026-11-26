import re,os
for name in ['s175-late','s175-cpugpu','s175','s192now','s191late']:
    log='/mnt/c/ios26/%s-log.bin'%name
    png='/mnt/c/ios26/%s-frame.png'%name
    if not os.path.exists(log):
        print(name,'NO LOG'); continue
    d=open(log,'rb').read().decode('utf-8','replace').replace('\0','')
    ts=re.findall(r'(\d\d:\d\d:\d\d)\.\d+\+0800',d)
    print('%-14s ts %s -> %s  | SpringBoard lines %d | panel swaps %d | iconservices %d' % (
        name, ts[0] if ts else '-', ts[-1] if ts else '-',
        d.count('SpringBoard[33'), d.count('panel swap'), d.count('iconservicesagent')))
