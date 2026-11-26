#!/bin/bash
# mks45.sh -- s45 = s44 + full-path aliases in inject.conf.
#
# exec_inject_env() matches imgp->ip_ndp->ni_cnd.cn_nameptr against each bare word in
# the config, requiring equal length.  PosterBoard gets its library (the "pb26:" lines
# prove it) while SpringBoard and backboardd do not ("sb26:" never appears) even though
# all three are named in the same line.  EXECDBG prints cn_pnbuf (the whole path),
# which is a different field, so we cannot tell from the log which one is compared.
#
# Appending the absolute path as an extra word is safe either way: matching is
# per-word and "any matched word in the group adds that group's library", so if the
# bare name is what matches, nothing changes; if the absolute path is what is compared,
# SpringBoard/backboardd start getting their libraries.
set -e
mkdir -p /root/star26/s45/work
rm -rf /root/star26/s45/work/root
cp -a /root/star26/s44/work/root /root/star26/s45/work/root

CONF=/root/star26/s45/work/root/etc/inject.conf
echo "== inject.conf before =="
md5sum "$CONF"; wc -c < "$CONF"

python3 - "$CONF" <<'PY'
import sys, re
p = sys.argv[1]
lines = open(p).read().splitlines()
SB = "/System/Library/CoreServices/SpringBoard.app/SpringBoard"
BB = "/usr/libexec/backboardd"
out = []
for ln in lines:
    if not ln.strip():
        out.append(ln)
        continue
    words = ln.split(" ")
    names = words[1:]
    extra = []
    if "SpringBoard" in names and SB not in names:
        extra.append(SB)
    if "backboardd" in names and BB not in names:
        extra.append(BB)
    out.append(" ".join(words + extra))
open(p, "w").write("\n".join(out) + "\n")
print("appended aliases to %d lines" % sum(1 for _ in lines))
PY

echo "== inject.conf after =="
md5sum "$CONF"; wc -c < "$CONF"
cat "$CONF"

cd /root/star26/s45/work
python3 /root/star26/hackios-xnu-userland/tools/apfs/mkapfs.py -z --plain fw \
	-o /root/star26/s45/root.apfs annibale=root 2>&1 | tail -1
cd /root/star26/star-native
python3 /mnt/d/桌面/star26-deps/scripts/make-boot.py s45 s44 "" loader_return_after=900 2>&1 | tail -3
bash /mnt/d/桌面/star26-deps/scripts/repack-ramdisk.sh s45 2>&1 | tail -3
ls -l /root/star26/s45/s45-boot.img
