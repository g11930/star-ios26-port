#!/bin/bash
U=/root/star26/hackios-xnu-userland/userland/src
echo "=== gfx dir ==="
ls $U/gfx | head -20
echo "=== pipeline cache hits ==="
grep -rn -i 'pipeline.*cache|cache.*pipeline|disk.*cache|cache_dir' $U/gfx 2>/dev/null | head -12
echo "=== AIR compile path ==="
grep -rn -i 'air_|Compile|compiler' $U/gfx/*.c 2>/dev/null | head -8
</