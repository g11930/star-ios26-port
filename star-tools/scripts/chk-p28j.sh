#!/bin/bash
# Decisive test: put "#error P28MARK" at the top of sleh.c and run the recorded compile
# command.  If the compile still succeeds, clang is not reading the file we edit.
set -e
S=/root/star26/kbuild/xnu-12377.121.6/osfmk/arm64/sleh.c
cp -f "$S" /root/sleh.c.p28bak
python3 - <<'EOF'
p = "/root/star26/kbuild/xnu-12377.121.6/osfmk/arm64/sleh.c"
t = open(p).read()
t = "#error P28MARK\n" + t
open(p, "w").write(t)
EOF
grep -c P28MARK "$S" || true
python3 - <<'EOF'
import json, subprocess, os
p = "/root/star26/kbuild/xnu-12377.121.6/BUILD/obj/RELEASE_ARM64_BCM2837/osfmk/RELEASE/sleh.o.json"
j, _ = json.JSONDecoder().raw_decode(open(p).read())
args = ["test.o" if a == "sleh.o" else a for a in j["arguments"]]
r = subprocess.run(args, cwd=j["directory"], capture_output=True, text=True)
print("rc:", r.returncode)
print("stderr head:", r.stderr[:400])
EOF
cp -f /root/sleh.c.p28bak "$S"
echo "restored"
