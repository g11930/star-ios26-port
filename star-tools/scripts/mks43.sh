#!/bin/bash
# mks43.sh -- s43 = s41 + diagnostics only, no driver-behaviour change.
#
# Goal: settle two facts that s41/s42 could not:
#   (1) which libannibaleair.dylib the running backboardd actually loads
#       -> the four "softpipe half lowering ..." strings are rewritten in place to
#          "STARMARK half lowering ..." (8 chars for 8 chars, same file offsets).
#          If the log says STARMARK the loaded image is ours; if it still says
#          softpipe, the image came from somewhere else (dyld shared cache).
#   (2) whether backboardd crashes inside the 900 s window at all
#       -> lsprobe ran as ONE process with four delays in s41/s42 and died after
#          the first sample (t=120 only).  Here it runs as four independent
#          processes so t=300/600/840 survive, and crash_files counts at those
#          times are directly comparable with the t=120 baseline.
#   starcat gets -n 60000 so the crash report's usedImages array is not truncated
#   (the report is 40768 B, -n 30000 cut it at the first image).
set -e
mkdir -p /root/star26/s43/work
rm -rf /root/star26/s43/work/root
cp -a /root/star26/s41/work/root /root/star26/s43/work/root

LIB=/root/star26/s43/work/root/lib/libannibaleair.dylib
echo "== lib before =="
md5sum "$LIB"; python3 /mnt/d/桌面/star26-deps/scripts/_uuid.py "$LIB"

python3 - "$LIB" <<'PY'
import sys
p = sys.argv[1]
d = bytearray(open(p, "rb").read())
OLD = b"softpipe half lowering"
NEW = b"STARMARK half lowering"
assert len(OLD) == len(NEW), (len(OLD), len(NEW))
n = 0
i = 0
while True:
    i = d.find(OLD, i)
    if i < 0:
        break
    d[i:i+len(OLD)] = NEW
    n += 1
    i += len(OLD)
open(p, "wb").write(d)
print("patched %d occurrences of %r -> %r" % (n, OLD.decode(), NEW.decode()))
PY

echo "== lib after =="
md5sum "$LIB"
python3 - "$LIB" <<'PY'
import sys, re
d = open(sys.argv[1], "rb").read()
print("STARMARK markers:", len(re.findall(rb"STARMARK half lowering", d)))
print("softpipe  markers left:", d.count(b"softpipe half lowering"))
for m in re.finditer(rb"STARMARK[ -~]{0,55}", d):
    print("   %#09x %s" % (m.start(), m.group(0).decode("ascii", "replace")))
PY

# ---- rc.jobs: four independent lsprobe processes, bigger starcat window ----
cat > /root/star26/s43/work/root/etc/rc.jobs <<'EOF'
# interactive: no synthetic touches, for a person holding the phone.
#
# s43 diagnostics: lsprobe is started four times, once per delay, instead of once
# with a list of delays -- in s41/s42 the single process produced t=120 only.
# starcat prints 60000 bytes so the crash report's usedImages is not truncated.
/annibale/bin/annsh &
/annibale/bin/trollstorehelper watch &
/annibale/bin/lsprobe 120 &
/annibale/bin/lsprobe 300 &
/annibale/bin/lsprobe 600 &
/annibale/bin/lsprobe 840 &
/annibale/bin/starcat -t 800 -n 60000 -p backboardd /private/var/mobile/Library/Logs/CrashReporter &
EOF
echo "== rc.jobs =="
cat /root/star26/s43/work/root/etc/rc.jobs

cd /root/star26/s43/work
python3 /root/star26/hackios-xnu-userland/tools/apfs/mkapfs.py -z --plain fw \
	-o /root/star26/s43/root.apfs annibale=root 2>&1 | tail -1
cd /root/star26/star-native
python3 /mnt/d/桌面/star26-deps/scripts/make-boot.py s43 s42 "" loader_return_after=900 2>&1 | tail -4
bash /mnt/d/桌面/star26-deps/scripts/repack-ramdisk.sh s43 2>&1 | tail -4
echo "== cmdline =="
tr -d '\0' < /root/star26/s43/parts/cmdline
echo
ls -l /root/star26/s43/s43-boot.img
