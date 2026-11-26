import re,os,time
p='/mnt/c/ios26/s193-logdump.bin'
print('file mtime', time.ctime(os.path.getmtime(p)))
d=open(p,'rb').read().decode('utf-8','replace').replace('\0','')
lines=[l for l in d.split('\n') if l.strip()]
# find all "== XNULOADER" markers and timestamps
print('XNULOADER markers:', d.count('XNULOADER'))
print('GOODIX_INIT_ENTERED:', d.count('GOODIX_INIT_ENTERED'))
print('stm: lines:', d.count('stm:'))
print('last 15 lines:')
for l in lines[-15:]: print('  ',l[:180])
# epoch from cmdline tells which image
for l in lines[:100]:
    if 'epoch=' in l:
        m=re.search(r'epoch=(\d+)',l)
        print('epoch in logdump:', m.group(1) if m else '?')
        break
# compare with s192 cmdline epoch
c=open('/root/star26/baseline/s193parts/cmdline','rb').read().decode().replace('\0','')
m=re.search(r'epoch=(\d+)',c)
print('epoch s192/s193 cmdline:', m.group(1) if m else '?')
