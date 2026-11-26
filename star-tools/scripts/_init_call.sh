#!/bin/bash
echo "=== reference: where is redwood_adreno_init called ==="
grep -n -B3 -A6 'redwood_adreno_init\|adreno_init' /root/g11930-ref/xnu/redwood.patch | head -40
echo
echo "=== reference: start_by_itself ==="
grep -n -A20 'start_by_itself' /root/g11930-ref/xnu/files/bsd/dev/redwood_adreno.c | head -30
