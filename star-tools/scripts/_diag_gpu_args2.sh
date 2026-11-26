#!/bin/bash
echo "=== [1] search adreno/gpu tokens directly in payloads ==="
python3 - <<'PY'
import re
for tag in ("s208","s215"):
    p="/root/star26/baseline/%sparts/%s-payload.bin"%(tag,tag)
    d=open(p,"rb").read()
    i=d.find(b"adreno")
    j=d.find(b"gpu=")
    k=d.find(b"fb_diff")
    print(tag,"size",len(d),"adreno@",i,"gpu=@",j,"fb_diff@",k)
    # dump the cmdline region around first fb_ token
    for tok in (b"fb_diff",b"star_display",b"gpu"):
        n=d.find(tok)
        if n>0:
            s=d[max(0,n-450):n+450]
            print("  ctx",tok,repr(s[:700]))
            break
PY
echo
echo "=== [2] K90 thermal & pipeline optimization doc (14 gears method) ==="
sed -n '1,90p' /root/star26/k90ref/docs/docs/progress/2026-11-09-thermal-and-pipeline-optimization.md
