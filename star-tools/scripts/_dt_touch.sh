#!/bin/bash
apt-get install -y device-tree-compiler >/dev/null 2>&1
which dtc || { echo "dtc missing"; exit 1; }
dtc -I dtb -O dts /root/star26/star-B.dtb 2>/dev/null | awk '/fts@0/{f=1} f{print} f&&/};/{exit}' | head -40
</>
