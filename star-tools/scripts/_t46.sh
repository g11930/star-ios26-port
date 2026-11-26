#!/bin/bash
L=/tmp/s200d.txt
echo "sb: $(grep -ac 'SpringBoard 33' $L)"
echo "pipelines: $(grep -ac 'render pipelines' $L)"
echo "ir3wait: $(grep -ac 'ir3 wait' $L)"
grep -a 'FBSDisplayLayoutService' $L | head -2
echo "--- last 5 timed lines"
grep -a '2025-12-10' $L | tail -5 | cut -c1-150