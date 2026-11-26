#!/bin/bash
echo "=== s178a env ==="
grep -a 'kern.annibale.env:' /tmp/s178a.txt | sed 's/.*kern.annibale.env:/env:/' | sort -u | head -12
echo "=== s178a iconservicesagent env? ==="
grep -a 'iconservicesagent:' /tmp/s178a.txt | head -4
</>
