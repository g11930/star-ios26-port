#!/bin/bash
F=/root/star26/star-native/iokit/Kernel/AnnibaleGPU.cpp
echo "== lines =="
wc -l "$F"
echo "== head 60 =="
sed -n '1,60p' "$F"
echo "== boot-arg / property lookups =="
grep -nE 'PE_parse_boot_argn|setProperty|IOService|Start\(|metal' "$F" | head -30
