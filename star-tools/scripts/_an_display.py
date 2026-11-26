p='C:/ios26/now-032636.bin'
d=open(p,'rb').read().decode('utf-8','replace').replace('\0','')
L=d.splitlines()
for kw in ['progress','Progress','splash','Splash','apple logo','Apple logo','logo','star_display','star: milestone','StarDisplay','framebuffer','fb:','fb_flip','fb_dcs','THE GPU STAYS','render pipelines','backboardd','WindowServer']:
    hits=[(i,l.strip()) for i,l in enumerate(L) if kw in l]
    if hits:
        print(f"===== {kw} ({len(hits)}) =====")
        for i,l in hits[:14]:
            print(f"  [{i}] {l[:185]}")
        print()
