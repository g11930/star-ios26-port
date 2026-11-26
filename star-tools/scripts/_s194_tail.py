import re
d=open('/mnt/c/ios26/s194-win-10.bin','rb').read().decode('utf-8','replace').replace('\0','')
lines=[l for l in d.split('\n') if l.strip()]
print('lines',len(lines))
# find ignite
for i,l in enumerate(lines):
    if 'ignite() returned' in l:
        print('ignite at line',i)
        print('--- after ignite (60 lines) ---')
        for j in range(i,min(len(lines),i+60)):
            print('  ',lines[j][:200])
        break
print('\n=== goodix/stm lines ===')
for l in lines:
    if re.search(r'goodix|stm:|GOODIX|touch',l,re.I):
        print('  ',l.strip()[:200])
