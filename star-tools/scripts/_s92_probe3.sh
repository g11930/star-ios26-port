#!/bin/bash
# 取证3：cmdline 精确抓取 + mtime + s90/s91 backboardd 时间线
D=/mnt/c/ios26
SRC=/root/star26/star-native
OUT=$D/probe3.out
: > "$OUT"
e(){ echo "$@" >> "$OUT"; }

e "===== 1) mod 时间：关键文件 ====="
for f in bsd/kern/mach_loader.c bsd/kern/kern_exec.c iokit/Kernel/MiniFramebufferUserClient.inc \
         bsd/kern/bsd_init.c osfmk/kern/startup.c; do
  e "$(stat -c '%y' $SRC/$f)  $f"
done

e ""
e "===== 2) cmdline 抓取（boot.img 明文区，搜 cpus=/metal=/star_cs） ====="
for n in 90 91 92; do
  e "--- s$n ---"
  # boot.img: 找 ASCII 里含 = 的长 token 串
  strings -n 6 "/mnt/c/ios26/s$n-boot.img" | grep -E "=" | grep -vE "^[A-Za-z_]+$" | grep -vE "^(com|org|apple|lib|usr|sys|private|System|Applications|dev|var|etc)" | head -40 >> "$OUT"
done

e ""
e "===== 3) 搜索 cmdline 明文（含 cpus 的长串） ====="
for n in 90 91 92; do
  e "--- s$n (grep cpus) ---"
  grep -a -o -E "[ -~]{0,400}cpus=[ -~]{0,400}" "/mnt/c/ios26/s$n-boot.img" | head -3 >> "$OUT"
done

echo OK; ls -l "$OUT"
