#!/bin/bash
T=/tmp/s139d.txt
echo "=== our own port messages (annibale:) ==="
grep -a '^annibale: ' $T | tail -14
echo
echo "=== backboardd: display / window / surface ==="
grep -aiE 'backboardd\[.*(window|display|surface|Metal)' $T | tail -14
echo
echo "=== s130 reference marker present? ==="
grep -ac 'start window server' /mnt/c/ios26/s130d-live.bin 2>/dev/null || echo "no s130 log"
</bash>
</
</bash>
