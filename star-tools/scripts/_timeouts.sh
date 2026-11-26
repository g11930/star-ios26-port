#!/bin/bash
for f in /tmp/s182c.txt /tmp/s175d.txt; do
  echo "--- $f"
  echo "timeout/wait lines: $(grep -aic 'timed out\|timeout\|retry after\|waiting for' $f)"
  grep -ai 'timed out\|timeout' $f | sed 's/.*\] //' | cut -c1-90 | head -8
  echo "wifi/baseband/aop: $(grep -aic 'wifid\|baseband\|aop\|sensor' $f)"
done
</>
