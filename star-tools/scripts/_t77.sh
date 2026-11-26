#!/bin/bash
echo "=== mkpayload.py head ==="
sed -n '1,60p' /root/star26/hackios-xnu-kernel/xnuloader/mkpayload.py
echo "..."
grep -n 'def \|struct\|magic\|PAYLOAD\|entry' /root/star26/hackios-xnu-kernel/xnuloader/mkpayload.py | head -30