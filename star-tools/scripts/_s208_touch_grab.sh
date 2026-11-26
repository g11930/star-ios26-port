#!/bin/bash
# s208 触摸验证抓日志：内核 alive，oem log + get_staged，抓两轮（间隔 5s），
# 分析 tl: p / tl: s / stm: 行，算触摸→画面提交端到端延迟。
export MSYS_NO_PATHCONV=1
F=/mnt/d/桌面/adb-fastboot/fastboot.exe
cd /mnt/c/ios26 || exit 1

echo "=== [1] device check ==="
timeout 6 "$F" devices 2>&1 | tr -d '\r' | grep xnuloader || { echo "xnuloader not present"; exit 1; }

for r in 1 2; do
  echo "=== [2.$r] oem log + get_staged ==="
  timeout 15 "$F" -s xnuloader oem log >/dev/null 2>&1
  rm -f "C:/ios26/s208-touch$r.bin"
  timeout 40 "$F" -s xnuloader get_staged "C:/ios26/s208-touch$r.bin" >/dev/null 2>&1
  sz=$(stat -c%s "/mnt/c/ios26/s208-touch$r.bin" 2>/dev/null || echo 0)
  echo "  s208-touch$r.bin size=$sz"
  [ "$r" = 1 ] && sleep 5
done

echo "=== [3] analysis ==="
python3 - <<'PY'
import re
for r in (1,2):
    p=f'/mnt/c/ios26/s208-touch{r}.bin'
    try: d=open(p,'rb').read().decode('utf-8','replace').replace('\0','')
    except Exception as e:
        print(f'-- touch{r}: read fail {e}'); continue
    L=[l.strip() for l in d.split('\n') if l.strip()]
    print(f'--- s208-touch{r}: {len(L)} lines ---')
    tl_p=[l for l in L if 'tl: p' in l]
    tl_s=[l for l in L if 'tl: s' in l]
    tl_c=[l for l in L if 'tl: c' in l]
    stm_stat=[l for l in L if 'so far' in l]
    swap=[l for l in L if 'swap #' in l]
    frames=[l for l in L if 'frames in' in l]
    print(f'  tl: p={len(tl_p)}  tl: s={len(tl_s)}  tl: c={len(tl_c)}')
    print(f'  stm stat lines={len(stm_stat)}  swap lines={len(swap)}  frames-in lines={len(frames)}')
    for l in stm_stat[-2:]: print('  [stat]', l[:200])
    for l in frames[-2:]: print('  [frames]', l[:160])
    for l in swap[-3:]: print('  [swap]', l[:140])
    print('  -- tl: p (last 15) --')
    for l in tl_p[-15:]: print('   ', l[:180])
    print('  -- tl: s (last 15) --')
    for l in tl_s[-15:]: print('   ', l[:180])
    # 尝试配对 p→s：抽 micros 数字
    def us(l):
        m=re.search(r'(\d{6,})\s*(us|µs|micros)?', l)
        return int(m.group(1)) if m else None
    ps=[(i,us(l),l) for i,l in enumerate(tl_p)]
    ss=[(i,us(l),l) for i,l in enumerate(tl_s)]
    pu=[u for _,u,_ in ps if u]; su=[u for _,u,_ in ss if u]
    if pu and su:
        print(f'  p micros: min={min(pu)} max={max(pu)} n={len(pu)}')
        print(f'  s micros: min={min(su)} max={max(su)} n={len(su)}')
        # 每个 p 找其后第一个 s，差值即端到端延迟
        lat=[]
        for _,u,_ in ps:
            if u is None: continue
            cand=[v for v in su if v>=u]
            if cand: lat.append(min(cand)-u)
        if lat:
            lat.sort()
            n=len(lat)
            print(f'  paired latencies n={n}: min={lat[0]}us p50={lat[n//2]}us p90={lat[int(n*0.9)]}us max={lat[-1]}us')
PY
echo "=== DONE ==="
