#!/bin/bash
echo "=== loader oem commands ==="
grep -rn '"oem\|oem ' /root/star26/star-native/../../ 2>/dev/null | head -0
for f in $(ls /root/star26/*loader* -d 2>/dev/null); do echo $f; done
grep -rln 'oem log' /root/star26 --include=*.c --include=*.cpp --include=*.h 2>/dev/null | head -5
</>
