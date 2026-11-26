#!/bin/bash
cd /root/star26/hackios-xnu-userland || exit 1
echo "=== tree ==="
ls
echo "=== userland/ ==="
ls userland | head -40
echo "=== build.sh head ==="
sed -n '1,60p' userland/build.sh
echo "=== demo plist ==="
cat userland/com.annibale.demo.plist
echo "=== demo source ==="
ls userland | grep -i demo
