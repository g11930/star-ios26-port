#!/bin/bash
B=/root/star26/s54/work/root/bin/input26-service
ls -l "$B"
md5sum "$B"
strings -a "$B" > /tmp/i26.strings
wc -l /tmp/i26.strings
for s in "services registered" "sample type" "standalone pid" "qos thread requested" "registration failed" "did not open" "HID service reset" "reading /dev/annibale-touch"; do
  n=$(grep -c "$s" /tmp/i26.strings)
  printf '%-32s %s\n' "$s" "$n"
done
