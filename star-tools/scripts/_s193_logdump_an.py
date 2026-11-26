import re
d=open('/mnt/c/ios26/s193-logdump.bin','rb').read().decode('utf-8','replace').replace('\0','')
lines=d.split('\n')
print('total lines',len(lines))
print('\n=== all panic contexts ===')
for i,l in enumerate(lines):
    if re.search(r'panic|data abort|KERNEL FAULT|fault|abort',l,re.I):
        print('--- L%d ---'%i)
        for j in range(max(0,i-2),min(len(lines),i+12)):
            print('  ',lines[j].strip()[:200])
print('\n=== all goodix/stm lines ===')
for i,l in enumerate(lines):
    if re.search(r'goodix|stm:|GOODIX|touch',l,re.I):
        print('L%d: %s'%(i,l.strip()[:220]))
print('\n=== last 30 non-empty lines ===')
ne=[l for l in lines if l.strip()]
for l in ne[-30:]: print('  ',l.strip()[:200])
