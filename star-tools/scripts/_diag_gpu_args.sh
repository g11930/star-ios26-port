#!/bin/bash
echo "=== [1] adreno args in current payload cmdline (s215) ==="
python3 - <<'PY'
import re
for name in ("s215-payload.bin","s208-payload.bin"):
    p="/root/star26/baseline/%sparts/%s"%(name.split("-")[0],name)
    try:
        d=open(p,"rb").read()
    except Exception as e:
        print(name,"ERR",e); continue
    m=re.search(rb"[ -~]{100,1100}", d)
    if not m: print(name,"no cmdline"); continue
    s=m.group(0).decode("ascii","replace")
    hits=[t for t in s.split() if any(k in t for k in ("adreno","gpu","fb_","pac_patch","display"))]
    print(name,"->",hits)
PY
echo
echo "=== [2] gpu-pwrlevels in any local dtb / vendor source ==="
grep -rl "gpu-pwrlevels" /root/star26 --include="*.dts" --include="*.dtsi" --include="*.txt" --include="*.c" 2>/dev/null | grep -v k90ref | head -10
echo
echo "=== [3] K90 gpu desktop accel doc (milestone method) ==="
ls /root/star26/k90ref/docs/docs/progress/ 2>/dev/null | head -30
