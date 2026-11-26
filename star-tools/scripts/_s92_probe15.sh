#!/bin/bash
# probe15: 收口 —— s89/s90 SpringBoard 卡点 / s91 SpringBoard 全生命周期 / sbmetal26 全量行
D=/mnt/c/ios26
OUT=$D/probe15.out
: > "$OUT"
e(){ echo "$@" >> "$OUT"; }
L(){ if [ "$1" = "s92" ]; then echo "$D/s92-staged.bin"; else echo "$D/s$1-log.bin"; fi; }

e "############ 1) s89/s90 SpringBoard 最后 30 行（卡在哪）"
for n in 89 90; do
  f=$(L $n)
  e "=== s$n SpringBoard ===  (总行数=$(strings -n 5 "$f" | grep -cE 'SpringBoard\[[0-9]+:'))"
  strings -n 5 "$f" | grep -E 'SpringBoard\[[0-9]+:' | tail -30 >> "$OUT"
done

e ""
e "############ 2) s91 SpringBoard[33] 全生命周期（首末 60 行）"
f=$(L 91)
e "-- 前 35 行 --"
strings -n 5 "$f" | grep -E 'SpringBoard\[33:' | head -35 >> "$OUT"
e "-- 最后 25 行 --"
strings -n 5 "$f" | grep -E 'SpringBoard\[33:' | tail -25 >> "$OUT"
e "-- SpringBoard[33] 含 Metal/GPU/MTL 的行 --"
strings -n 5 "$f" | grep -E 'SpringBoard\[33:' | grep -iE 'metal|gpu|mtl|IOAccel|sgx' >> "$OUT"

e ""
e "############ 3) s91/s92: error=22 首次出现的上下文（前 8 行）"
for n in 91 s92; do
  f=$(L $n)
  e "=== $n ==="
  ln=$(strings -n 5 "$f" | grep -n 'error=22' | head -1 | cut -d: -f1)
  e "  首个 error=22 在 strings 行号 $ln"
  strings -n 5 "$f" | sed -n "$((ln>8?ln-8:1)),$((ln+4))p" >> "$OUT"
done

e ""
e "############ 4) sbmetal26 全部行（s89/s90 vs s91/s92）"
for n in 89 90 91 s92; do
  f=$(L $n)
  e "=== $n ==="
  strings -n 5 "$f" | grep -E 'sbmetal26' | head -40 >> "$OUT"
done

e ""
e "############ 5) AnnibaleMetal 全部行（s89/s90 vs s91）"
for n in 89 90 91; do
  f=$(L $n)
  e "=== $n ==="
  strings -n 5 "$f" | grep -E 'annibalemetal|AnnibaleMetal' | grep -vE '^\-rwx|^\-rw\-|^drwx' | head -25 >> "$OUT"
done

e ""
e "############ 6) IOAcceleratorES 全部行"
for n in 89 90 91 s92; do
  f=$(L $n)
  e "=== $n ==="
  strings -n 5 "$f" | grep -E 'IOAcceleratorES|IOAccelerator' | head -25 >> "$OUT"
done

e ""
e "############ 7) 'registration device' / 'adopted native default device' 行（关键分叉）"
for n in 89 90 91 s92; do
  f=$(L $n)
  e "=== $n ==="
  strings -n 5 "$f" | grep -E 'registration device|adopted native default|default_before' >> "$OUT"
done

e ""
e "############ 8) s90/s91: 系统级 'metal' / 'GPU' 相关内核行"
for n in 90 91; do
  f=$(L $n)
  e "=== s$n ==="
  strings -n 5 "$f" | grep -iE 'metal=|gpu started|gpu was not started|theGPUisnotstarted' | head -20 >> "$OUT"
done

echo OK; ls -l "$OUT"
