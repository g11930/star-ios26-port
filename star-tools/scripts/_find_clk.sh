#!/bin/bash
echo "--- vendor clock headers on disk ---"
find /root -maxdepth 4 -name '*clock*.h' 2>/dev/null | grep -i 'sm8350\|lahaina\|msm8998' | head -8
echo "--- any sm8350 gcc dtsi ---"
find /root -maxdepth 5 \( -name '*sm8350*' -o -name '*lahaina*' \) 2>/dev/null | head -10
echo "--- dtc: neighbours of spi@a8c000 ---"
sed -n '18280,18300p' /tmp/star.dts
</