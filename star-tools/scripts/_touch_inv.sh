#!/bin/bash
echo "=== reference (g11930-ref) touch files ==="
find /root/g11930-ref -iname '*touch*' 2>/dev/null | head -20
echo "=== our touch files ==="
find /root/star26/star-native /root/star26/hackios-xnu-userland/userland/src -iname '*touch*' 2>/dev/null | head -20
echo "=== reference mentions of annibale-touch ==="
grep -rln 'annibale-touch' /root/g11930-ref 2>/dev/null | head -10
</