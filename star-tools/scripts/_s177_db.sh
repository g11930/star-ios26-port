#!/bin/bash
for f in /tmp/s177c.txt /tmp/s177b_log.txt /tmp/s177a_log.txt; do
  echo "--- $f"
  grep -c 'thumb group' $f
  grep -c 'sync matched' $f
  grep -c 'annibalemetal\[SpringBoard' $f
done
echo "=== SpringBoard env in earliest log ==="
grep -a 'kern.annibale.env: SpringBoard' /tmp/s177a_log.txt | head -6
</>
