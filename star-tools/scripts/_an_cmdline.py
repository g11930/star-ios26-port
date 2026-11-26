import os
# 从日志直接读 cmdline（日志里第77行有完整 cmdline）
for name in ['now-032817.bin','s210-alive210.bin','s211-now.bin','s208-now.bin']:
    p='C:/ios26/'+name
    if not os.path.exists(p): continue
    d=open(p,'rb').read().decode('utf-8','replace').replace('\0','')
    for l in d.splitlines():
        if l.startswith('cmdline:'):
            print(f"=== {name} ===")
            print(l[:1100])
            print()
            # 关键 boot-arg 检查
            for kw in ['star_cs_keep_valid','star_cs_valid','pac_patch','pac_patch_fips','gpu_irq','amfi','cs_enforcement','autounlock']:
                print(f"  {kw}: {'YES' if kw in l else 'no'}")
            print()
            break
