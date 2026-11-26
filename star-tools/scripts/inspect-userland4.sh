#!/bin/bash
U=/root/star26/hackios-xnu-userland
echo "=== build.sh env (80-130) ==="
sed -n '80,130p' "$U"/userland/build.sh
echo "=== metal build block (340-370) ==="
sed -n '340,370p' "$U"/userland/build.sh
echo "=== ios26 dir ==="
ls "$U"/ios26 2>/dev/null | head -10
echo "=== obj present? ==="
ls -la "$U"/userland/obj/libannibalemetal.dylib 2>/dev/null
