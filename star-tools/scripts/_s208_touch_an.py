import re,sys
d=open('/mnt/c/ios26/s208-touch1.bin','rb').read().decode('utf-8','replace').replace('\0','')
L=[l.strip() for l in d.split('\n') if l.strip()]
print("lines:",len(L))
for k in ['PANIC','haltRestart','pac: page','mount-phase-2']:
    print(f"  {k}:",sum(1 for l in L if k in l))

# 1) 日志时间戳是否前进
ts=re.compile(r'(2025-\d\d-\d\d|\w{3} \d\d) [\d:]{8}')
all_ts=[m.group(0) for l in L if (m:=ts.search(l))]
if all_ts:
    print("\n=== log timestamps ===")
    print("  first:",all_ts[0],"| last:",all_ts[-1],"| n=",len(all_ts))
    uniq=[]
    for t in all_ts:
        if not uniq or uniq[-1]!=t: uniq.append(t)
    print("  transitions:",len(uniq))
    print("  first 6:",uniq[:6])
    print("  last 6:",uniq[-6:])
else:
    print("\n  (no calendar timestamps found; sample fmt lines below)")
    for l in L[:3]: print("   ",l[:150])

# 2) 帧率证据
fr=[l for l in L if 'frames in' in l]
sw=[l for l in L if 'swap #' in l]
print("\n=== display ===")
print("  'frames in' lines:",len(fr)," swap lines:",len(sw))
for l in fr[-4:]: print("  [frames]",l[:160])
for l in sw[-3:]: print("  [swap]",l[:140])
m=[l for l in L if re.search(r'under 17ms|over 17ms|in 100|in 1000',l)]
for l in m[-3:]: print("  [budget]",l[:160])

# 3) timer / 延迟 / 卡顿报警
print("\n=== timer/delay warnings ===")
tw=[l for l in L if re.search(r'[Tt]imer|delayed|hang|stuck|slow|deadline|watchdog',l)]
print("  matched:",len(tw))
for l in tw[-15:]: print("   ",l[:170])

# 4) 触摸统计（确认正常）
print("\n=== touch ===")
stat=[l for l in L if 'so far' in l]
for l in stat[-2:]: print("  [stat]",l[:200])
print("  tl: p/s/c:",sum(1 for l in L if 'tl: p' in l),sum(1 for l in L if 'tl: s' in l),sum(1 for l in L if 'tl: c' in l))

# 5) 最后 12 行
print("\n=== last 12 lines ===")
for l in L[-12:]: print("   ",l[:170])
