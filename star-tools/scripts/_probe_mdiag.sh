#!/bin/bash
D=/root/star26/hackios-xnu-kernel/tools/userland-driver
echo "== diag output channel =="
grep -n "say\|fprintf\|ANNIBALE_DIAG\|annibale_diag" "$D"/annibalemetal_diag.inc 2>/dev/null | head -20
echo
echo "== how diag decides to speak =="
sed -n '1,60p' "$D"/annibalemetal_diag.inc 2>/dev/null
