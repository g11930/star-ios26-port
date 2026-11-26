#!/bin/bash
echo "=== D:/ios26 images (top level) ==="
ls -lh /d/ios26/*.img 2>/dev/null | tail -40
echo "=== any iOS16/ipados17 assets ==="
ls -d /d/ios26/*16* /d/ios26/*17* /d/ios26/*ipad* 2>/dev/null
echo "=== sealed iOS16 XNU tree ==="
wsl.exe -d Ubuntu-24.04 -- bash -c 'ls -ld /root/star-build/xnu-src/xnu-8796.121.2 2>&1; ls /root/star-build/*.sh 2>/dev/null; echo "---loader---"; ls -l /root/star26/xnuloader/*.py 2>/dev/null'
