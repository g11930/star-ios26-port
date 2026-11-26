#!/bin/bash
echo "=== processes carrying our metal shim ==="
grep -a -oE 'annibalemetal\[[A-Za-z0-9_.\-]+' /tmp/iconprobe.txt | sort | uniq -c | sort -rn | head -10
echo "=== shim refusals / failures ==="
grep -a -E 'annibalemetal|annibale-gl|rwa ' /tmp/iconprobe.txt | grep -ai 'refus|fail|nil|null|not done|empty|zero' | sed 's/.*] //' | cut -c1-100 | head -12
echo "=== iconservicesagent presence ==="
grep -ac 'iconservicesagent' /tmp/iconprobe.txt
grep -a 'iconservicesagent' /tmp/iconprobe.txt | head -4
echo "=== png/asset decode ==="
grep -ai 'IOSurface\|CGImage\|ImageIO\|ISIcon' /tmp/iconprobe.txt | tail -6