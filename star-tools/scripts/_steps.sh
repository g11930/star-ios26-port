#!/bin/bash
T=/tmp/s133d.txt
echo "=== step transitions ==="
grep -aE 'adreno: step [0-9]+:' $T | sed 's/^adreno: //' | head -30
echo
echo "=== last adreno lines ==="
grep -a 'adreno' $T | tail -22
echo
echo "=== failures / not started ==="
grep -aiE 'adreno:.*(fail|not|give|error|timeout|stopped|refus)' $T | head -12
</bash>
