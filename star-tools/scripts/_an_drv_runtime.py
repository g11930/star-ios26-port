import glob,os,re
fs=sorted(glob.glob(r"C:/ios26/now-*.bin"), key=os.path.getmtime)
p=fs[-1]; d=open(p,'rb').read().decode('utf-8','replace').replace('\x00','')
L=d.splitlines()
print("LOG:",os.path.basename(p),"lines:",len(L))
# annibale 驱动 init 行（去重复前缀，取唯一 init 事件）
drv=['goodix','adsp','audio','mic','camera','iris','bt_','bluetooth','wifi','wlan','80211','modem','qmi','qrtr','battery','haptic','sensors','cpufreq','rpmh','ipa','net','ufs','input','torch','buttons','image','hfi']
for name in drv:
    hits=[(i,l.strip()) for i,l in enumerate(L) if re.search(r'\b'+re.escape(name),l,re.I)]
    # 只需首条 init + 任何 fail
    init=[h for h in hits if re.search(r'init|start|register|probe|entered|open|up|ready|found',h[1],re.I)][:3]
    fail=[h for h in hits if re.search(r'fail|error|cannot|unable|timeout|no such|not found|panic|assert',h[1],re.I)][:3]
    print(f"\n=== {name}: total={len(hits)} ===")
    for i,l in init: print(f"  +[{i}] {l[:170]}")
    for i,l in fail: print(f"  ![{i}] {l[:170]}")
