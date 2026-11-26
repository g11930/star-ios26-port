p='C:/ios26/now-032817.bin'
d=open(p,'rb').read().decode('utf-8','replace').replace('\0','')
L=d.splitlines()
def c(s): return sum(1 for l in L if s in l)
for k in ['unlockedEnvironmentMode','render pipelines','swap#','swap ','StarGUI','milestone',
          'SystemShell','PosterBoard','activation_installed','SpringBoard','backboardd',
          'MiniIOMobileFramebuffer','16 frames','fps','1 a second','PANIC','haltRestart',
          'not a platform binary','fipspost_post_integrity']:
    print(f"  {k}: {c(k)}")
print()
print("=== SystemShell / activation / PosterBoard 关键行 ===")
for i,l in enumerate(L):
    s=l.strip()
    if any(k in s for k in ['SystemShell] activate','activation_installed','[SystemShell]','PosterBoard[37']):
        print(f"[{i}] {s[:190]}")
