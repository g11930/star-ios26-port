#!/bin/bash
# s92: what EXACTLY does containermanagerd do to decide NOT_CODESIGNED?
# It queries the target process's code signing info. The error happens in
# _container_query_get_result_at_index INSIDE backboardd (client side).
# The client-side libcontainer checks the signing identity of ITSELF (backboardd).
# cs_flags=0x26000000 => CS_SIGNED|CS_PLATFORM_BINARY but NOT CS_VALID (bit 0)!
# On real iOS CS_VALID is set when the blob validated. Here CS_VALID is missing!
# Look at containermanagerd_system query results for backboardd identifier
python3 -c "
data=open('/mnt/c/ios26/s91-log.bin','rb').read().decode('utf-8',errors='replace')
lines=[l for l in data.split(chr(10)) if l.strip()]
import re
# context around first NOT_CODESIGNED error
for i,l in enumerate(lines):
    if 'NOT_CODESIGNED' in l:
        for j in range(max(0,i-12), min(len(lines), i+8)):
            print(('[%s] ' % ('C' if j==i else ' ')) + lines[j][:200])
        print('======')
        break
"
