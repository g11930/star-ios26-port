#!/bin/bash
# s92: THE DECISIVE QUESTION: does backboardd's binary on the phone carry an
# LC_CODE_SIGNATURE load command at all, and was load_code_signature even reached?
# Evidence path A: s91 kernel log lines 'load code signature error' or CODE SIGNING
python3 -c "
data=open('/mnt/c/ios26/s91-log.bin','rb').read().decode('utf-8',errors='replace')
lines=[l for l in data.split(chr(10)) if l.strip()]
import re
pats=['load code signature error','CODE SIGNING','load_code_signature','check_signature','validation of code signature','failed to verify main binary']
for p in pats:
    hits=[l for l in lines if p in l]
    print(f'--- {p}: {len(hits)}')
    for h in hits[:6]: print('  ',h[:210])
"
