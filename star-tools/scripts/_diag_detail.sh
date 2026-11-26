#!/bin/bash
D=/root/star26/hackios-xnu-kernel/tools/userland-driver
echo "=== ANNIBALE_DIAG usage context ==="
grep -rn -B6 -A10 'getenv("ANNIBALE_DIAG")' $D/annibalemetal_device.inc | head -30
echo "=== sync log ==="
grep -rn -B4 -A8 'ANNIBALE_SYNC_LOG' $D/annibalemetal_diag.inc | head -20
</>
