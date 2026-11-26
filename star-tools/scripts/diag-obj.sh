#!/bin/bash
# Inspect the star object files: does star_log() really call vsnprintf and
# loader_log_line, or has the compiler replaced them with stubs?
O=/root/star26/star-native/BUILD/obj/RELEASE_ARM64_BCM2837
NM=/root/star-build/xnu-deps/host/bin/nm
OD=/usr/bin/llvm-objdump
for f in "$O/bsd/RELEASE/star_display_handoff.o" "$O/bsd/RELEASE/kern_exec.o" "$O/osfmk/RELEASE/loader_return.o"; do
  echo "=== $f"
  ls -l "$f"
  echo "-- symbols"
  "$NM" -n "$f" 2>&1 | grep -F -e 'star_log' -e 'star_display_milestone' -e 'vsnprintf' -e 'snprintf' -e 'loader_log_line' -e 'loader_log_putc' -e 'star_trace' -e 'star_gate' | head -30
  echo "-- disassembly of star_log / star_trace (first 90 lines)"
  "$OD" -d "$f" 2>&1 | head -90
done
echo "=== compile flags for star_display_handoff.c"
python3 - <<'PY'
import json
p="/root/star26/star-native/BUILD/obj/RELEASE_ARM64_BCM2837/compile_commands.json"
try:
    cc=json.load(open(p))
except Exception as e:
    print("no compile_commands:", e); raise SystemExit
for e in cc:
    if "star_display_handoff" in e.get("file","") or "kern_exec.c" in e.get("file",""):
        print(e["file"])
        cmd=e.get("command","")
        print("  has -Dsnprintf?", "-Dsnprintf" in cmd, " has -Dvsnprintf?", "-Dvsnprintf" in cmd)
        print("  NO_PRINTF:", [x for x in cmd.split() if "PRINTF" in x])
PY
echo "=== DONE"
