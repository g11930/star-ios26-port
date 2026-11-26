import re, sys
p = '/mnt/c/ios26/s211-now.bin'
d = open(p, 'rb').read().decode('utf-8', 'replace').replace('\0', '')
L = d.splitlines()
def c(s): return sum(1 for l in L if s in l)

print("total lines:", len(L))
print()
print("=== FIPS gate verdict ===")
print("  'About to call FIPS_POST':", c('About to call the FIPS_POST'))
print("  'Returned from FIPS_POST':", c('Returned from calling the FIPS_POST'))
print("  fips integrity PASSED:", sum(1 for l in L if 'fipspost_post_integrity' in l and 'PASSED' in l))
print("  fips integrity FAILED:", sum(1 for l in L if 'fipspost_post_integrity' in l and 'FAILED' in l))
print()
print("=== boot progress ===")
for k in ['mount-phase-2','keybagd','MKB_INIT','SpringBoard','backboardd',
          'render pipelines','THE GPU STAYS','unlockedEnvironmentMode',
          'star: milestone','StarDisk: published']:
    print(f"  {k}: {c(k)}")
print()
print("=== crash ===")
for k in ['PANIC','haltRestart','not a platform binary','userspace panic']:
    print(f"  {k}: {c(k)}")
print()
# pac page vs fips ordering
fi = [i for i,l in enumerate(L) if 'FIPSPOST' in l and 'Module-ID' in l]
pi = [i for i,l in enumerate(L) if 'pac: page' in l]
print("=== pac:page vs FIPS ordering ===")
print("  FIPS module-id line:", fi[:2] if fi else "none")
print("  pac:page count:", len(pi), "| first line:", pi[0] if pi else "-", "| last:", pi[-1] if pi else "-")
if fi and pi:
    print("  pages BEFORE fips:", sum(1 for i in pi if i < fi[0]),
          "| pages AFTER fips:", sum(1 for i in pi if i > fi[0]))
traps=[int(m.group(1)) for l in L for m in [re.search(r'traps=(\d+)',l)] if m]
print("  pac traps: first", traps[0] if traps else 0, "last", traps[-1] if traps else 0)
print()
print("=== last wallclock ===")
ts=[m.group(1) for l in L for m in [re.search(r'(\d{4}-\d\d-\d\d \d\d:\d\d:\d\d)',l)] if m]
print("  ", ts[0] if ts else '-', "..", ts[-1] if ts else '-')
print()
print("=== last 20 non-tl/pac lines ===")
n=0
for l in reversed(L):
    s = l.strip()
    if not s or 'tl: c' in s or s.startswith('pac:'): continue
    print("   ", s[:170]); n+=1
    if n>=20: break
