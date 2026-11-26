#!/bin/bash
# Same as chk-p28h but tolerant of the concatenated .o.json format.
set -e
python3 - <<'EOF'
import json, subprocess, os
p = "/root/star26/kbuild/xnu-12377.121.6/BUILD/obj/RELEASE_ARM64_BCM2837/osfmk/RELEASE/sleh.o.json"
s = open(p).read()
j, end = json.JSONDecoder().raw_decode(s)
args = ["test.o" if a == "sleh.o" else a for a in j["arguments"]]
print("cwd:", j["directory"], "nargs:", len(args))
r = subprocess.run(args, cwd=j["directory"], capture_output=True, text=True)
print("rc:", r.returncode)
if r.stderr:
    print("stderr:", r.stderr[-600:])
t = os.path.join(j["directory"], "test.o")
if os.path.exists(t):
    d = open(t, "rb").read()
    print("test.o size", len(d), "P28FAULT", d.count(b"P28FAULT"))
else:
    print("no test.o")
EOF
