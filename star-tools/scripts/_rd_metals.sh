#!/bin/bash
R=/root/star26
echo "=== metal_stubdev files ==="
find "$R" -name "*metal_stub*" -o -name "*stubdev*" 2>/dev/null | grep -v "\.o$" | head -20
echo
echo "=== who installs it ==="
grep -rn "metal_stubdev" "$R/hackios-xnu-userland" 2>/dev/null | head -20
