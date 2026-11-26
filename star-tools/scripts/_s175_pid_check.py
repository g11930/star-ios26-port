import re
d=open('/mnt/c/ios26/s175-late-log.bin','rb').read().decode('utf-8','replace').replace('\0','')
# SpringBoard PIDs seen
pids=sorted(set(int(x) for x in re.findall(r'SpringBoard\[(\d+):',d)))
print('SpringBoard PIDs:', pids)
sb=re.findall(r'SpringBoard\[(\d+):\d+\]',d)
print('SpringBoard line count:', len(sb))
# check for launchd re-launch of SpringBoard (crash loop signature)
for pat in ['exited','kill','SIGABRT','SIGSEGV','crash','Jetsam','jetsam','Reboot','reboot']:
    c=d.count(pat)
    if c: print('  %-12s %d' % (pat,c))
# timestamp span
ts=re.findall(r'(\d\d:\d\d:\d\d)\.\d+\+0800',d)
print('first ts', ts[0] if ts else '-', ' last ts', ts[-1] if ts else '-')
# display / desktop evidence
for k in ['SB + backlight-on','displayState: on','WakeOnTapEnabled','icon','SpringBoard.33']:
    print('  %-20s %d' % (k,d.count(k)))
