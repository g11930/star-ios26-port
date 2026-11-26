#!/bin/bash
F=/root/star26/hackios-xnu-kernel/tools/userland-driver/annibalemetal_device.inc
echo "== size =="
wc -l "$F"
echo "== 40-140 =="
sed -n '40,140p' "$F"
