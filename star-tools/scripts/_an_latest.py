import re,os
p=r"C:/ios26/now-042429.bin"; d=open(p,'rb').read().decode('utf-8','replace').replace('\x00','')
L=d.splitlines(); print("lines:",len(L))
# 崩溃判据
for kw in ['non-platform','userspace panic','PANIC','KERNEL FAULT','haltRestart','BOOT FALLBACK','panic(']:
    print(f"  {kw}: {sum(1 for l in L if kw in l)}")
# 进桌面判据
for kw in ['unlockedEnvironmentMode','swap#','SystemShell] activate','UserInteractiveFocal','activation_installed','PosterBoard','render pipelines','springboardd','SpringBoard[','backboardd']:
    print(f"  {kw}: {sum(1 for l in L if kw in l)}")
# 最后时间线
import re as R
tl=[l.strip() for l in L if R.search(r'2025-12-10 \d\d:\d\d:\d\d',l)]
print("=== 最后 8 条时间线 ===")
for l in tl[-8:]: print("  "+l[:190])
# pac 最后
pac=[l.strip() for l in L if 'pac: traps' in l]
print("pac last:", pac[-1][:190] if pac else 'none')
# 驱动 init 行（annibale 前缀）
print("=== 驱动 init/fail 行 ===")
for i,l in enumerate(L):
    if re.search(r'(goodix|adreno|adsp|audio|mic|camera|iris|bt_|bluetooth|wifi|80211|modem|qmi|battery|haptic|sensor|input26):.*(init|start|fail|error|register|entered|open|not |unable)',l,re.I):
        print(f"  [{i}] {l.strip()[:180]}")
