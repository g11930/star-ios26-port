#!/bin/bash
cd /mnt/d/ios26 || exit 1
L=now-083621.bin
echo "=== FILE ==="; ls -la "$L"
echo
echo "=== KEYWORD COUNTS ==="
for k in 'panic:' 'PANIC' 'panic' 'fault' 'Fault' 'error' 'ERROR' 'failed' 'FAIL' 'refused' 'denied' 'timeout' 'watchdog' 'assert' 'Assertion' 'backtrace' 'abort' 'stalled' 'SMMU' 'translation' 'unable to' 'WARNING' 'Warning'; do
  printf '%-16s %s\n' "$k" "$(grep -a -c "$k" "$L")"
done
echo
echo "=== panic/fault lines (non-cmdline) ==="
grep -a -i -E 'panic|fault' "$L" | grep -a -v -E 'panic_on_crash|fault 0|cmdline|BOOT_LINE' | head -20
echo
echo "=== SMMU fault-ish lines ==="
grep -a 'SMMU' "$L" | grep -a -i -E 'fault|refus|denied|error|fail|invalid' | head -10
echo
echo "=== error/fail/warn sample ==="
grep -a -i -E 'error|failed|unable to|warning' "$L" | head -25
echo
echo "=== tail 15 ==="
tail -c 4000 "$L" | tr -d '\0' | tail -15
