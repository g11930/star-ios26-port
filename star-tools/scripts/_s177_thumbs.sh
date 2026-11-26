#!/bin/bash
echo "=== any thumb lines ==="
grep -a -i 'thumb' /tmp/s177c.txt | head -12
echo "=== env applied per process ==="
grep -a 'kern.annibale.env' /tmp/s177c.txt | sed 's/.*kern.annibale.env:/env:/' | head -20
</>
