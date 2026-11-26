import re
p='/mnt/c/ios26/s208-slow-1.bin'
d=open(p,'rb').read().decode('utf-8','replace').replace('\0','')
L=[l.strip() for l in d.splitlines() if l.strip()]
print("=== total lines:", len(L), "===")

def c(s): return sum(1 for l in L if s in l)

# 1. PAC traps counters over time
print("\n=== [1] PAC traps progression ===")
traps=[l for l in L if 'pac: traps' in l]
print("  trap counter lines:", len(traps))
if traps:
    vals=[]
    for l in traps:
        m=re.search(r'traps=(\d+)', l)
        if m: vals.append(int(m.group(1)))
    if vals:
        print("  first:", vals[0], " last:", vals[-1], " delta:", vals[-1]-vals[0])
        # unique progression samples
        uniq=[]
        for v in vals:
            if not uniq or v!=uniq[-1]: uniq.append(v)
        print("  unique counter steps:", len(uniq))
        for v in uniq[:5]: print("   ", v)
        print("    ...")
        for v in uniq[-5:]: print("   ", v)

# 2. milestone / phase markers with any timing
print("\n=== [2] milestone & phase markers ===")
for l in L:
    if re.search(r'milestone|StarDisk: published|mount-phase-2|unlockedEnvironment|THE GPU STAYS|launchd|boot task|render pipelines', l, re.I):
        print("  ", l[:180])

# 3. timer delays / slow warnings
print("\n=== [3] timer delays / slow / delayed warnings ===")
delays=[l for l in L if re.search(r'delay|slow|took \d|wait.*\d+ ?(ms|s)|Timer', l, re.I)]
print("  count:", len(delays))
for l in delays[:40]:
    print("  ", l[:180])

# 4. wall-clock timestamp span (userspace logs carry 2025-xx-xx HH:MM:SS)
print("\n=== [4] wall-clock timestamp span ===")
ts=[]
for l in L:
    m=re.match(r'\s*(\d{4}-\d\d-\d\d \d\d:\d\d:\d\d)', l)
    if m: ts.append(m.group(1))
print("  timestamped lines:", len(ts))
if ts:
    print("  first:", ts[0], " last:", ts[-1])

# 5. uptime / micros counters (tl: c, stm)
print("\n=== [5] uptime / micros counters ===")
for k in ['tl: c','so far','frames in','swap #','stm:']:
    kl=[l for l in L if k in l]
    print(f"  {k}: {len(kl)}")
    for l in kl[-2:]: print("     ", l[:170])

# 6. kernel boot timing lines (chrono / time / clock)
print("\n=== [6] boot time accounting ===")
for l in L:
    if re.search(r'(boot|startup|init|launchd).{0,40}(\d+\.?\d* ?(s|sec|ms|second)|took|elapsed)', l, re.I):
        print("  ", l[:180])
