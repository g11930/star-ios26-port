#!/bin/bash
# s92: the two daemons' actual query context - find containermanagerd_system pid and its errors
python3 -c "
data=open('/mnt/c/ios26/s91-log.bin','rb').read().decode('utf-8',errors='replace')
lines=[l for l in data.split(chr(10)) if l.strip()]
# containermanagerd_system
cms=[l for l in lines if 'containermanagerd_system' in l]
print('cm_system mentions:',len(cms))
for h in cms[:15]: print(h[:220])
print()
# error=22 SecTask - what cs_flags 26000000 means: CS_VALID|CS_ADHOC|CS_LINKER_SIGNED? decode
# CS_VALID=1, CS_ADHOC=2, CS_GET_TASK_ALLOW=4, CS_RESTRICT=0x800, CS_PLATFORM_BINARY=0x04000000
v=0x26000000
print('cs_flags 0x26000000 =', hex(v))
print('  CS_VALID(0x1):', bool(v&1))
print('  CS_ADHOC(0x2):', bool(v&2))
print('  CS_SIGNED(0x20000000):', bool(v&0x20000000))
print('  CS_PLATFORM_BINARY(0x04000000):', bool(v&0x04000000))
print('  CS_LINKER_SIGNED(0x20000):', bool(v&0x20000))
"
