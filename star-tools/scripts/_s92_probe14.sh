#!/bin/bash
# probe14: 收敛取证 —— s90 基线是否真"好" + s91 pid39 死因 + 88s 空档定位
D=/mnt/c/ios26
OUT=$D/probe14.out
: > "$OUT"
e(){ echo "$@" >> "$OUT"; }
L(){ if [ "$1" = "s92" ]; then echo "$D/s92-staged.bin"; else echo "$D/s$1-log.bin"; fi; }

e "############ 1) 各轮 error=22 / cs_flags=26000000 计数"
for n in 89 90 91 s92; do
  f=$(L $n)
  e "  $n : error22=$(strings -n 5 "$f" | grep -c 'error=22')  cs26000000=$(strings -n 5 "$f" | grep -c 'cs_flags=26000000')  SecTaskLoad=$(strings -n 5 "$f" | grep -c 'SecTaskLoadEntitlements failed')  NOT_CODESIGNED=$(strings -n 5 "$f" | grep -c 'NOT_CODESIGNED')"
done

e ""
e "############ 2) SpringBoard 生命周期（各轮首末 + P28EXIT + 是否有 Terminating）"
for n in 89 90 91 s92; do
  f=$(L $n)
  e "=== $n ==="
  strings -n 5 "$f" | grep -E 'SpringBoard\[[0-9]+:' | head -1 >> "$OUT"
  strings -n 5 "$f" | grep -E 'SpringBoard\[[0-9]+:' | tail -1 >> "$OUT"
  e "  P28EXIT SpringBoard=$(strings -n 5 "$f" | grep -c 'P28EXIT: pid [0-9]* SpringBoard')"
  e "  SpringBoard Terminating=$(strings -n 5 "$f" | grep -cE 'SpringBoard\[[0-9]+:.*Terminating')"
  strings -n 5 "$f" | grep -E 'P28EXIT: pid [0-9]* SpringBoard' >> "$OUT"
done

e ""
e "############ 3) s91: pid 39 的死亡记录（各处提及 :39 的 termination/exit）"
strings -n 5 "$D/s91-log.bin" | grep -E 'backboardd>:39|backboardd>: *39|pid 39 |pid:39|\[39\]|:39\b' | grep -viE '\[39:[0-9]+\]' | head -40 >> "$OUT"

e ""
e "############ 4) s91: pid 39 最后一行之后到 pid190 之前，全局日志（03:03:54 .. 03:05:42）"
strings -n 5 "$D/s91-log.bin" | grep -E '^2025-12-10 03:0[34]' | grep -vE 'runningboardd|backboardd' | sed -n '1,80p' >> "$OUT"

e ""
e "############ 5) s89/s90 digitizer 获取时间戳（含 after 秒数）"
for n in 89 90; do
  f=$(L $n)
  e "=== s$n ==="
  strings -n 5 "$f" | grep -E 'acquired main display digitizer|digitizer attached' >> "$OUT"
done

e ""
e "############ 6) s90/s91: 首个 SpringBoard 时间 + 首个 P28EXIT 时间（启动推进深度）"
for n in 89 90 91 s92; do
  f=$(L $n)
  e "  $n firstSB=$(strings -n 5 "$f" | grep -oE 'SpringBoard\[[0-9]+:[0-9]+\]' | head -1)  firstP28=$(strings -n 5 "$f" | grep -oE '^2025-12-10 [0-9:.+]* .*P28EXIT.*' | head -1 | awk '{print $1" "$2}')"
done

e ""
e "############ 7) s90 backboardd[39] 03:03:52.7 .. 03:05:31 之间是否有任何一行（验证真空档）"
e "-- s90 [39] 在 03:04 时段的行数 --"
strings -n 5 "$D/s90-log.bin" | grep -E 'backboardd\[39:' | grep -c '^2025-12-10 03:04' >> "$OUT"
e "-- s90 [39] 03:05:2x..03:05:3x 前 12 行 --"
strings -n 5 "$D/s90-log.bin" | grep -E 'backboardd\[39:' | grep -E '^2025-12-10 03:05:[23]' | head -12 >> "$OUT"

e ""
e "############ 8) s90/s91: display / framebuffer / splash / star_display 相关"
for n in 90 91; do
  f=$(L $n)
  e "=== s$n ==="
  for k in 'IOFramebuffer' 'splash' 'display' 'StarDisk' 'annibale' 'IOAcceleratorES'; do
    e "  $(printf '%-18s' "$k") $(strings -n 5 "$f" | grep -c -- "$k")"
  done
done

e ""
e "############ 9) s91: AnnibaleMetal 上下文 20 行（谁加载的）"
strings -n 5 "$D/s91-log.bin" | grep -nE 'AnnibaleMetal|sbmetal26' | head -3 | while IFS=: read ln rest; do
  e "  --- line $ln 前后 ---"
  strings -n 5 "$D/s91-log.bin" | sed -n "$((ln>5?ln-5:1)),$((ln+5))p" >> "$OUT"
done

echo OK; ls -l "$OUT"
