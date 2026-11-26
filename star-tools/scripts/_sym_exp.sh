#!/bin/bash
D=/root/star26/s34/work/root/lib/libannibale-sbmetal-experiment.dylib
nm -gU "$D" 2>/dev/null | head -40
echo "=== all symbols (uc) ==="
nm -U "$D" 2>/dev/null | grep -i 'sbmetal\|register\|adopt' | head -20
echo "=== init/ctor sections ==="
otool -l "$D" 2>/dev/null | grep -A4 '__mod_init' | head -12 || true
</