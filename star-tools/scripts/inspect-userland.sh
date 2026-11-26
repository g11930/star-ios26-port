#!/bin/bash
K=/root/star26/hackios-xnu-kernel
U=/root/star26/hackios-xnu-userland
echo "=== userland tree top ==="
ls "$U" 2>/dev/null | head -20
echo "=== kernel tree top ==="
ls "$K" 2>/dev/null | head -20
echo "=== build scripts ==="
ls "$K"/tools/userland-driver/*.sh "$K"/userland/*.sh "$U"/*.sh 2>/dev/null
echo "=== who builds libannibalemetal ==="
grep -rln 'libannibalemetal' "$K"/tools/userland-driver/ "$K"/userland/ "$U" 2>/dev/null | head -10
echo "=== git status of kernel tree ==="
cd "$K" && git log --oneline -3 2>/dev/null && git status --porcelain 2>/dev/null | head -10
