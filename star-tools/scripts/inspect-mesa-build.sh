#!/bin/bash
U=/root/star26/hackios-xnu-userland/tools
echo "=== mk-mesa.sh head ==="
sed -n '1,60p' "$U/mk-mesa.sh"
echo
echo "=== build dirs ==="
ls -d /root/star26/hackios-xnu-userland/tools/out 2>/dev/null && ls /root/star26/hackios-xnu-userland/tools/out | head -20
ls -d /root/star26/hackios-xnu-userland/tools/mesa-build 2>/dev/null
find /root -maxdepth 6 -name 'build.ninja' -path '*mesa*' 2>/dev/null | head -5
echo
echo "=== grep SP_MAX_TEXTURE_SIZE ==="
grep -rn "SP_MAX_TEXTURE_SIZE" /root/star-build/xnu-deps/build/mesa/mesa-25.0.7/src/gallium/drivers/softpipe/*.h | head -5
