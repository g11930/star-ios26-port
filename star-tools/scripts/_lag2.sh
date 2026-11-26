#!/bin/bash
echo "=== GET_PARAM refusals ==="
grep -a -E 'answered 0x|not known here|GET_PARAM|refused' /tmp/lp.txt | tail -20
echo "=== per-process fallbacks ==="
grep -a -i -E 'software|fallback|softpipe|no screen|unusable' /tmp/lp.txt | tail -12
echo "=== pipeline compile totals ==="
grep -a 'render pipelines: ' /tmp/lp.txt | tail -10
</>
