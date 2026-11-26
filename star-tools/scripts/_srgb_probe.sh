#!/bin/bash
D=/root/star26/hackios-xnu-kernel/tools/userland-driver
echo "=== sRGB handling in shim ==="
grep -rn 'sRGB\|_srgb\|SRGB' $D/*.inc $D/*.m | head -20
echo "=== unsupported format prints ==="
grep -rn 'unsupported\|not supported\|refus' $D/annibalemetal_texture*.inc | head -10
</>
