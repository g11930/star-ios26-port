#!/bin/bash
cd /mnt/d/ios26 || exit 1
L=now-083621.bin
echo "=== Assertion lines (sample) ==="
grep -a -i 'assert' "$L" | head -12
echo
echo "=== watchdog / stalled / timeout ==="
grep -a -i -E 'watchdog|stalled|timeout' "$L" | head -20
echo
echo "=== D2F10V / wait us ==="
grep -a -E 'D2F10V|wait: CS|wait: ' "$L" | head -15
echo
echo "=== kernel-level prefixes (annibale/adreno/star/SoC/pmap/kalloc) ==="
grep -a -i -E '(annibale|adreno|star26|star:|pmap|kalloc|vm_fault|SoC|WCOMB)' "$L" | grep -a -i -E 'error|fail|warn|abort|fault|panic|invalid|refus|denied|assert' | head -20
echo
echo "=== ERROR (uppercase) exact ==="
grep -a 'ERROR' "$L" | head -10
