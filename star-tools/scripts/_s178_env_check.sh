#!/bin/bash
echo "=== env lines (s178b) ==="
grep -a 'kern.annibale.env:' /tmp/s178b.txt | sed 's/.*kern.annibale.env:/env:/' | sort -u | head -20
echo "=== iconservicesagent pid refs ==="
grep -a -oE 'iconservicesagent\[[0-9]+' /tmp/s178b.txt | sort -u | head -4
echo "=== shim loaded in iconservicesagent? ==="
grep -a 'annibalemetal\[iconservicesagent' /tmp/s178b.txt | head -4
</>
