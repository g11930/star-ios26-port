#!/bin/bash
echo "=== who builds render pipelines ==="
grep -a 'render pipelines' /tmp/s184a.txt | sed -E 's/.*annibalemetal\[([^]]*)\].*render pipelines: ([0-9]+) built.*/\1 built \2/' | sort | uniq -c | head -8
echo "=== iconservicesagent mentions ==="
grep -a -c 'iconservicesagent' /tmp/s184a.txt
grep -a 'iconservicesagent' /tmp/s184a.txt | tail -3
echo "=== executable loads ==="
grep -a 'EXECDBG: loading /usr/libexec/icon\|EXECDBG: loading .*iconservices' /tmp/s184a.txt | head -4
echo "=== desktop yet? icons drawing ==="
grep -a -c 'IOSvcIn: SpringBoard' /tmp/s184a.txt