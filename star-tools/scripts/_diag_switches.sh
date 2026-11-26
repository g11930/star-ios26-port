#!/bin/bash
D=/root/star26/hackios-xnu-kernel/tools/userland-driver
echo "=== diag switches ==="
grep -n 'getenv("ANNIBALE' $D/annibalemetal_diag.inc | head -30
echo "=== texture upload / replaceRegion ==="
grep -rn 'replaceRegion\|rw_texture_upload\|tex_upload' $D/*.inc $D/*.m | head -12
</>
