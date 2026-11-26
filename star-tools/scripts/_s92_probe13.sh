#!/bin/bash
# probe13: PID 重启矩阵（s89..s92）+ s92 探针是否真编入内核
D=/mnt/c/ios26
SRC=/root/star26/star-native
OUT=$D/probe13.out
: > "$OUT"
e(){ echo "$@" >> "$OUT"; }
L(){ if [ "$1" = "s92" ]; then echo "$D/s92-staged.bin"; else echo "$D/s$1-log.bin"; fi; }

e "############ 1) 各进程 PID 集合与重启次数（核心指标）"
for n in 89 90 91 s92; do
  f=$(L $n)
  e "=== $n ==="
  for p in SpringBoard backboardd runningboardd launchd cfprefsd; do
    pids=$(strings -n 5 "$f" | grep -oE "$p\[[0-9]+:" | grep -oE '\[[0-9]+' | tr -d '[' | sort -n -u | tr '\n' ',' | sed 's/,$//')
    cnt=$(echo "$pids" | tr ',' '\n' | grep -c .)
    e "  $(printf '%-16s' "$p") uniquePIDs=$cnt  -> $pids"
  done
done

e ""
e "############ 2) backboardd 各 PID 的生命窗口（首末时间戳）"
for n in 89 90 91 s92; do
  f=$(L $n)
  e "=== $n ==="
  strings -n 5 "$f" | grep -oE "backboardd\[[0-9]+:[0-9]+\]" | grep -oE 'backboardd\[[0-9]+' | sed 's/backboardd\[//' | sort -n -u | while read pid; do
    first=$(strings -n 5 "$f" | grep "backboardd\[$pid:" | head -1 | awk '{print $1" "$2}')
    last=$(strings -n 5 "$f" | grep "backboardd\[$pid:" | tail -1 | awk '{print $1" "$2}')
    e "  pid $pid : $first  ->  $last"
  done
done

e ""
e "############ 3) 'Handshake succeeded' / 'Identity resolved' 计数（runningboard 就绪度）"
for n in 89 90 91 s92; do
  f=$(L $n)
  e "  $n : handshake_ok=$(strings -n 5 "$f" | grep -c 'Handshake succeeded')  ident=$(strings -n 5 "$f" | grep -c 'Identity resolved as osservice<com.apple.backboardd>')  acquiring=$(strings -n 5 "$f" | grep -c 'acquired main display digitizer')"
done

e ""
e "############ 4) s92 探针是否真编入内核（三重验证）"
s92k=/root/star26/s92/parts/kernelcache
e "-- 4a) 内核文件位置 --"
ls -la /root/star26/s92/parts/ 2>/dev/null | head -20 >> "$OUT"
e "-- 4b) 内核里是否含探针字符串 --"
for f in $(find /root/star26/s92 -name 'kernel*' -o -name '*.im4p' 2>/dev/null | head -5); do
  e "  file=$f size=$(stat -c%s $f 2>/dev/null)"
  e "    star_cs_keep_valid : $(strings -n 6 "$f" 2>/dev/null | grep -c 'star_cs_keep_valid')"
  e "    star_cs_probe      : $(strings -n 6 "$f" 2>/dev/null | grep -c 'star_cs_probe')"
  e "    CS_INITPAGE_BAD    : $(strings -n 6 "$f" 2>/dev/null | grep -c 'CS_INITPAGE_BAD')"
done
e "-- 4c) 对照：s91 内核 --"
for f in $(find /root/star26/s91 -name 'kernel*' -o -name '*.im4p' 2>/dev/null | head -5); do
  e "  file=$f size=$(stat -c%s $f 2>/dev/null)  CS_INITPAGE=$(strings -n 6 "$f" 2>/dev/null | grep -c 'CS_INITPAGE')"
done

e ""
e "############ 5) mach_loader.c 探针代码 + 是否被 stage 脚本回滚"
e "-- 探针关键行 --"
grep -n "star_cs_keep_valid\|star_cs_probe\|CS_INITPAGE" "$SRC/bsd/kern/mach_loader.c" | head -20 >> "$OUT"
e "-- mach_loader.c mtime --"
stat -c '%y %s %n' "$SRC/bsd/kern/mach_loader.c" >> "$OUT"
e "-- s92 parts 各文件 mtime --"
ls -la --time-style=full-iso /root/star26/s92/parts/ 2>/dev/null | head -25 >> "$OUT"

e ""
e "############ 6) s91[190] 从 startup 到崩溃完整序列（找 BiometricKit 触发点）"
strings -n 5 "$D/s91-log.bin" | grep -E "backboardd\[190:" | sed -n '25,90p' >> "$OUT"

echo OK; ls -l "$OUT"
