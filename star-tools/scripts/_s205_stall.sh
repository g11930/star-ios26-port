#!/bin/bash
python3 - <<'PY'
import re
d = open('/mnt/c/ios26/s205-cur.bin','rb').read().decode('utf-8','replace').replace('\0','')
lines = d.split('\n')

def show(kw, ctx=2, maxn=8):
    idx = [i for i,l in enumerate(lines) if kw.lower() in l.lower()]
    print('== %s (%d hits) ==' % (kw, len(idx)))
    for i in idx[:maxn]:
        for j in range(max(0,i-ctx), min(len(lines), i+ctx+1)):
            print('%6d| %s' % (j, lines[j][:180]))
        print('   ---')

show('hang')
show('stall')
show('IOAccelerator')
show('fence')
show('kernel')
PY
