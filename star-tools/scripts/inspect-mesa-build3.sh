#!/bin/bash
T=/root/star26/hackios-xnu-userland/tools
echo "=== mk-mesa.sh 60-140 ==="
sed -n '60,140p' "$T/mk-mesa.sh"
echo "=== SDKs available ==="
ls /root/theos/sdks/
echo "=== other mesa build trees ==="
find /root -maxdepth 7 -type d -name 'build-softpipe*' 2>/dev/null | head
find /root -maxdepth 8 -name 'libannibaleair.dylib' 2>/dev/null | head
