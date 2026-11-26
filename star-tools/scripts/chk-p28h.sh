#!/bin/bash
# Run the exact compile command xnu recorded for sleh.c, into test.o, and see whether the
# probe text lands in the object.  This separates "make did not run it" from "the compiler
# did not keep it".
set -e
D=/root/star26/kbuild/xnu-12377.121.6/BUILD/obj/RELEASE_ARM64_BCM2837/osfmk/RELEASE
python3 - <<'EOF'
import json, subprocess, os
p = "/root/star26/kbuild/xnu-12377.121.6/BUILD/obj/RELEASE_ARM64_BCM2837/osfmk/RELEASE/sleh.o.json"
j = json.load(open(p))
args = j["arguments"]
args = ["test.o" if a == "sleh.o" else a for a in args]
print("cwd:", j["directory"])
print("nargs:", len(args))
r = subprocess.run(args, cwd=j["directory"], capture_output=True, text=True)
print("rc:", r.returncode)
print("stderr tail:", r.stderr[-800:])
t = os.path.join(j["directory"], "test.o")
if os.path.exists(t):
    d = open(t, "rb").read()
    print("test.o size", len(d), "P28FAULT", d.count(b"P28FAULT"))
else:
    print("no test.o")
EOF
