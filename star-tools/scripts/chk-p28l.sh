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
for k in ("User parity error.", "csm_code_signing_violation", "codes[1] = fault_addr",
          "P28FAULT", "self_restrict_mode", "handle_user_abort(arm_saved_state_t"):
    print("%-40s %d" % (k, t.count(k)))
k = t.rfind("handle_user_abort(")
print("--- tail of the last handle_user_abort region ---")
print(t[k:k+700])
EOF
