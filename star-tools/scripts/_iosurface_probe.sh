#!/bin/bash
K=/root/star26/hackios-xnu-kernel
echo "=== iosurface binding in our glue ==="
grep -rn 'IOSurface' $K/tools/userland-driver/*.inc $K/tools/userland-driver/*.m 2>/dev/null | head -12
echo "=== mesa side iosurface ==="
grep -rn -i 'iosurface' /root/star26/hackios-xnu-userland/userland/src 2>/dev/null | head -8
echo "=== docs on black icons / iosurface limits ==="
grep -rln -i 'black icon\|icons are black\|IOSurface' /root/star26/hackios-xnu-kernel/docs 2>/dev/null | head -6
</>
