#!/bin/bash
set -u
echo "== s41 dir =="
ls -1 /root/star26/s41 2>/dev/null | head -30
echo "== find libannibale* / bundles =="
find /root/star26 -maxdepth 7 \( -name 'libannibale*' -o -name 'AnnibaleMetal.bundle' -o -name '*Mesa*' -o -name 'libOSMesa*' \) 2>/dev/null | sort | head -40
echo "== work/root presence =="
ls -1d /root/star26/*/work 2>/dev/null | head
ls -1d /root/star26/*/root 2>/dev/null | head
