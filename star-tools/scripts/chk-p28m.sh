#!/bin/bash
set -e
python3 - <<'EOF'
import json, subprocess
p = "/root/star26/kbuild/xnu-12377.121.6/BUILD/obj/RELEASE_ARM64_BCM2837/osfmk/RELEASE/sleh.o.json"
j, _ = json.JSONDecoder().raw_decode(open(p).read())
args = j["arguments"]
out, i = [], 0
while i < len(args):
    a = args[i]
    if a in ("-c", "-g", "-MMD"):
        i += 1; continue
    if a in ("-o", "-MF", "-MT"):
        i += 2; continue
    out.append(a); i += 1
out.append("-E")
r = subprocess.run(out, cwd=j["directory"], capture_output=True, text=True)
t = r.stdout
for k in ("_consume_kprintf_args", "CONFIG_NO_KPRINTF_STRINGS", "P28FAULT",
          "task_pid(current_task())"):
    print("%-32s %d" % (k, t.count(k)))
k = t.find("P28FAULT")
k2 = t.find("task_pid(current_task())")
print("--- around the probe call ---")
if k2 >= 0:
    print(repr(t[k2-260:k2+160]))
EOF
