#!/bin/bash
export MSYS_NO_PATHCONV=1
F=/mnt/d/桌面/adb-fastboot/fastboot.exe
cd /mnt/c/ios26 || exit 1
OUT=/mnt/c/ios26/s94-live3.bin

echo "=== [$(date +%T)] grab fresh live log ==="
rm -f "$OUT"
timeout 40 "$F" -s xnuloader oem log 2>&1 | tr -d '\r' | tail -2
for try in 1 2 3; do
  timeout 45 "$F" -s xnuloader get_staged "C:/ios26/s94-live3.bin" 2>&1 | tr -d '\r' | tail -2
  [ -s "$OUT" ] && { echo "captured $(stat -c %s "$OUT") bytes"; break; }
  sleep 2
done

echo "=== [$(date +%T)] problem-focused analysis ==="
python3 - "$OUT" <<'PY'
import sys, os, re, collections
p=sys.argv[1]
if not os.path.exists(p) or os.path.getsize(p)==0:
    print("NO LOG"); sys.exit(0)
d=open(p,'rb').read(); t=d.decode('utf-8','replace').replace('\0','')
lines=[l for l in t.split('\n') if l.strip()]
print("size",len(d),"lines",len(lines))
# last timestamp
ts=re.findall(r'\d{4}-\d\d-\d\d \d\d:\d\d:\d\d',t)
print("time span:", ts[0] if ts else "?", "->", ts[-1] if ts else "?")
# error/warning keyword frequency
keys=["error","Error","ERROR","fail","Fail","FAIL","timeout","Timeout","timed out",
      "did not find","No such","unable","Unable","could not","Could not","denied","Denied",
      "exception","Exception","crash","Crash","abort","Abort","invalid","Invalid",
      "not found","not present","nil","NULL","(null)","missing","Missing"]
c=collections.Counter()
for k in keys: c[k]=t.count(k)
print("\n=== error/warning keyword counts ===")
for k,v in c.most_common():
    if v: print("  %-16s %d"%(k,v))

# distinctive error lines (dedup by pattern, keep last 3 distinct)
print("\n=== distinctive ERROR/FAIL lines (last 12) ===")
cand=[]
for l in lines:
    if re.search(r'\b(error|Error|ERROR|fail|Fail|exception|Exception|crash|abort|denied)\b',l) and len(l)>40:
        cand.append(l)
for l in cand[-12:]: print("  ",l[:200])

# last 40 lines overall
print("\n=== last 40 lines ===")
for l in lines[-40:]: print("  ",l[:200])
PY
echo "=== [$(date +%T)] DONE"
