#!/bin/bash
L=/mnt/c/ios26/s62-staged.bin
echo "=== PROC COUNT (s62 vs s61d baseline=53) ==="
strings "$L" | grep -oE 'EXECDBG: loading [^ ]+' | sed 's/EXECDBG: loading //' | sort -u | wc -l
echo "=== KEY ON-DEMAND SERVICES ==="
for s in cfprefsd configd securityd keybagd lsd MTLCompilerService nanoregistryd backboardd SpringBoard logd; do
  printf '%-20s ' "$s"
  strings "$L" | grep -c "EXECDBG: loading [^ ]*$s"
done
echo "=== SURFACE / FRAME ==="
strings "$L" | grep -E 'created surface|render pipelines|first_frame|First swap|swap ' | head -12
echo "=== CHECK-IN / BOGUS ==="
strings "$L" | grep -iE 'bogus check-in|is_connection_for_service|filter_policy|checkin' | head -10
echo "=== CACHE / BOOT ==="
strings "$L" | grep -E 'Unable to load cache|Cache sent to launchd|Early boot complete' | head -5
echo "=== MSGFROBE PEER (unique) ==="
strings "$L" | grep -oE 'peer=[^ ]+' | sort | uniq -c | sort -rn | head -12
echo "=== HEARTBEAT LAST ==="
strings "$L" | grep -E 'say (9|17|33) trace' | tail -4
echo "=== PANIC ==="
strings "$L" | grep -iE 'panic|data abort|Kernel data' | grep -v 'cmdline:' | head -5
