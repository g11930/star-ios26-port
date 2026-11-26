#!/bin/bash
echo "--- pinctrl node for phandle 0x1fe ---"
grep -n 'phandle = <0x1fe>' /tmp/star.dts
L=$(grep -n 'phandle = <0x1fe>' /tmp/star.dts | cut -d: -f1 | head -1)
[ -n "$L" ] && sed -n "$((L-12)),$((L+3))p" /tmp/star.dts
echo "--- pins used ---"
awk -v l="$L" 'NR<l && NR>l-14' /tmp/star.dts | grep -n 'pins ='
</>
