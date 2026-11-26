#!/bin/bash
cd /root/star26/star-native
echo "=== cpu frequency control ==="
grep -rn -i 'cpufreq\|cpu.*freq\|perf_state\|dcvs' --include=*.c --include=*.cpp bsd/dev/star osfmk/arm64 2>/dev/null | grep -v BUILD | head -12
echo "=== rpmh votes in star drivers ==="
grep -rn 'rpmh\|RPMh' --include=*.c bsd/dev/star 2>/dev/null | grep -i 'vote\|cx\|perf' | head -10
</<EOF>
