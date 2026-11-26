#!/bin/bash
# s92: what did warsaw/dada logs show around 'start window server' and containermanagerd?
# Also: does either reference show containermanagerd_system working?
echo "===WARSAW-GOLDEN==="
grep -n 'window server\|containermanager\|container' /root/ref/warsaw/docs/v37/log-tail.txt 2>/dev/null | head -15
echo "===DADA-DOCS==="
find /root/ref/dada/docs -name '*.txt' -o -name '*.md' 2>/dev/null | head -10
