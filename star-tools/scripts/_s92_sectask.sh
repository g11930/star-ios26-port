#!/bin/bash
# s92: the real question — where does the iOS26 containermanagerd get its idea of
# whether an identifier is "signed"? It asks SecCode / Security framework, which
# asks the kernel via csops(CS_OPS_IDENTITY) or CS_OPS_STATUS.
# Our chain: proc CS flags must have CS_SIGNED for identity to be returned.
# Also 'SecTaskLoadEntitlements: failed to get cs_flags, error=3' appears in s91?
echo "===S91-SECTASK==="
python3 -c "
data=open('/mnt/c/ios26/s91-log.bin','rb').read().decode('utf-8',errors='replace')
lines=[l for l in data.split(chr(10)) if l.strip()]
hits=[l for l in lines if 'SecTaskLoadEntitlements' in l]
print('SecTask count:',len(hits))
import re
pids={}
for h in hits:
    m=re.search(r'pid=(\d+)',h)
    if m: pids[m.group(1)]=pids.get(m.group(1),0)+1
print('by pid:',pids)
print()
for h in hits[:5]: print(h[:200])
print()
# containermanagerd startup lines
cm=[l for l in lines if 'containermanagerd' in l]
print('containermanagerd lines:',len(cm))
for h in cm[:20]: print(h[:200])
"
