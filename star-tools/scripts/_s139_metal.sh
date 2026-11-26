#!/bin/bash
T=/tmp/s139d.txt
echo "=== backboardd / sbmetal / metal after the open ==="
grep -a 'annibalemetal\|sbmetal26\|\[Metal\]\|MetalPlugin\|IOAccelerator' $T | head -30
echo
echo "=== window server related anywhere ==="
grep -aiE 'window ?server|CAWindowServer|CA::Render|render server' $T | head -12
</bash>
