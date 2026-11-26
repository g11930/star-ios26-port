import re
p='/mnt/c/ios26/s209-crash.bin'
d=open(p,'rb').read().decode('utf-8','replace').replace('\0','')
L=[l.strip() for l in d.splitlines() if l.strip()]
print("lines:", len(L))
def c(s): return sum(1 for l in L if s in l)
print("PANIC:", c('PANIC'), "| haltRestart:", c('haltRestart'),
      "| pac: page:", c('pac: page'), "| pac: traps:", c('pac: traps'),
      "| mount-phase-2:", c('mount-phase-2'))
print("\n=== all PANIC/panic/halt lines ===")
for l in L:
    if re.search(r'PANIC|panic|haltRestart|not a platform binary|failed|Failed|FAILED', l):
        print("  ", l[:200])
print("\n=== pac lines ===")
for l in L:
    if 'pac' in l.lower():
        print("  ", l[:200])
print("\n=== full tail (last 60) ===")
for l in L[-60:]:
    print("  ", l[:200])
