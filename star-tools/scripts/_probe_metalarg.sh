#!/bin/bash
set -u
S=/root/star26/star-native
echo "== boot-args we recognise that look GPU/display related =="
grep -rhoE 'PE_parse_boot_argn\("[a-z0-9_]+"' "$S/bsd" "$S/osfmk" 2>/dev/null | sed 's/.*("//; s/"//' | sort -u | head -60
echo
echo '== does the kernel know "metal"? =='
grep -rn '"metal"' "$S/bsd" "$S/osfmk" 2>/dev/null | head -10
echo
echo '== fb_ / display / iomfb boot args =='
grep -rhoE 'PE_parse_boot_argn\("(fb|iomfb|metal|gpu|display)[a-z0-9_]*"' "$S/bsd" "$S/osfmk" 2>/dev/null | sed 's/.*("//; s/"//' | sort -u
