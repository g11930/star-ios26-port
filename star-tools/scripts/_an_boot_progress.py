import sys, re, glob, os
p = sys.argv[1] if len(sys.argv)>1 else '/mnt/c/ios26/now-staged.bin'
if not os.path.exists(p):
    p = '/c/ios26/' + os.path.basename(p)
d = open(p,'rb').read().decode('utf-8','replace').replace('\0','')
L = d.splitlines()
def c(s): return sum(1 for l in L if s in l)

print("FILE:", p, "bytes:", os.path.getsize(p), "lines:", len(L))
print()
print("=== [1] loader / 进度条 / Apple logo 相关 ===")
for k in ['progress','Progress','PROGRESS','bar','splash','Splash','apple','Apple','logo','Logo',
          'fb:','framebuffer','display','Display','DPU','dpu','fb_flip','fb_dcs','fb_dim',
          'StarDisplay','star_display','load','Load','LOAD','bootx','BootX','kernel','Kernel']:
    n=c(k)
    if n: print(f"  {k}: {n}")
print()
print("=== [2] 启动阶段 marker ===")
for k in ['StarDisk: published','mount-phase-2','keybagd','MKB_INIT','SpringBoard','backboardd',
          'render pipelines','THE GPU STAYS','unlockedEnvironmentMode','WindowServer','loginwindow',
          'launchd','fips','FIPS','FIPSPOST','About to call the FIPS_POST','Returned from calling the FIPS_POST',
          'AMFI','ElfLoad','cs_keep','not a platform binary','userspace panic','PANIC','haltRestart',
          'star: milestone','swap','paging','launchd_init']:
    n=c(k)
    if n: print(f"  {k}: {n}")
print()
print("=== [3] FIPS verdict ===")
print("  integrity PASSED:", sum(1 for l in L if 'fipspost_post_integrity' in l and 'PASSED' in l))
print("  integrity FAILED:", sum(1 for l in L if 'fipspost_post_integrity' in l and 'FAILED' in l))
print("  FIPS_POST returned:", c('Returned from calling the FIPS_POST'))
fi=[i for i,l in enumerate(L) if 'FIPSPOST' in l and 'Module-ID' in l]
pi=[i for i,l in enumerate(L) if 'pac: page' in l]
print("  FIPS module-id line:", fi[0] if fi else '-')
print("  pac:page count:", len(pi), "before FIPS:", sum(1 for i in pi if fi and i<fi[0]), "after:", sum(1 for i in pi if fi and i>fi[0]))
traps=[int(m.group(1)) for l in L for m in [re.search(r'traps=(\d+)',l)] if m]
print("  traps first/last:", traps[0] if traps else 0, "/", traps[-1] if traps else 0)
print()
print("=== [4] 时间线 (wallclock) ===")
ts=[m.group(1) for l in L for m in [re.search(r'(\d{4}-\d\d-\d\d \d\d:\d\d:\d\d)',l)] if m]
print("  ", ts[0] if ts else '-', "..", ts[-1] if ts else '-', " count:", len(ts))
upt=[m.group(1) for l in L for m in [re.search(r'uptime[:\s]+(\d+)',l,re.I)] if m]
print("   uptime mentions:", upt[-5:] if upt else '-')
print()
print("=== [5] 最后 35 条非噪声行 ===")
n=0
for l in reversed(L):
    s=l.strip()
    if not s or 'tl: c' in s or s.startswith('pac:'): continue
    print("   ", s[:180]); n+=1
    if n>=35: break
