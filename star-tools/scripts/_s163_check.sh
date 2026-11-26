#!/bin/bash
strings -n 5 /mnt/c/ios26/s163d-live.bin > /tmp/s163.txt
echo "goodix count: $(grep -a -c -i goodix /tmp/s163.txt)"
grep -a -i 'goodix' /tmp/s163.txt | head -14
echo "--- tail ---"
tail -6 /tmp/s163.txt
</>
