#!/bin/bash
dtc -I dtb -O dts /root/star26/star-B.dtb 2>/dev/null > /tmp/star.dts
echo "--- path of fts (search upward) ---"
grep -n 'fts@0' /tmp/star.dts | head -2
awk 'NR>=1' /tmp/star.dts | grep -n 'spi@' | head -10
echo "--- nearest spi parent containing fts ---"
awk '/spi@[0-9a-f]+ \{/{p=$0; ln=NR} /fts@0 \{/{print ln": "p; exit}' /tmp/star.dts
</>
