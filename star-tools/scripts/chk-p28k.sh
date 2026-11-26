#!/bin/bash
# Preprocess sleh.c with the recorded flags and look for the probe text.  If it is gone at
# this stage, the block sits inside a conditional the build turns off.
set -e
python3 - <<'EOF'
import json, subprocess, os
p = "/root/star26/kbuild/xnu-12377.121.6/BUILD/obj/RELEASE_ARM64_BCM2837/osfmk/RELEASE/sleh.o.json"
j, _ = json.JSONDecoder().raw_decode(open(p).read())
args = j["arguments"]
out = []
i = 0
while i < len(args):
    a = args[i]
    if a in ("-c", "-o", "-g", "-MMD", "-MF", "-MT"):
        i += 2 if a in ("-o", "-MF", "-MT") else 1
        continue
    out.append(a)
    i += 1
out.append("-E")
r = subprocess.run(out, cwd=j["directory"], capture_output=True, text=True)
print("rc:", r.returncode, "outlen:", len(r.stdout))
t = r.stdout
print("P28FAULT in preprocessed:", t.count("P28FAULT"))
print("handle_user_abort in preprocessed:", t.count("handle_user_abort"))
if "P28FAULT" in t:
    k = t.index("P28FAULT")
    print("context:", repr(t[k-300:k+120]))
EOF
