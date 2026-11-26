#!/bin/bash
U=/root/star26/hackios-xnu-userland
K=/root/star26/hackios-xnu-kernel
echo "=== build.sh head ==="
sed -n '1,70p' "$U"/userland/build.sh
echo "=== src list ==="
ls "$U"/userland/src/ 2>/dev/null | head -25
echo "=== texture.inc client_memory in userland tree ==="
grep -c 'client-memory copy allocation failed' "$U"/userland/src/annibalemetal_texture.inc 2>/dev/null
echo "=== texture.inc client_memory in kernel tree ==="
grep -c 'client-memory copy allocation failed' "$K"/tools/userland-driver/annibalemetal_texture.inc 2>/dev/null
echo "=== md5 both ==="
md5sum "$U"/userland/src/annibalemetal_texture.inc "$K"/tools/userland-driver/annibalemetal_texture.inc 2>/dev/null
