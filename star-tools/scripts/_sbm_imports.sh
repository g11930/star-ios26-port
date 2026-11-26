#!/bin/bash
set -u
L=/root/star26/s44/work/root/lib/libannibale-sbmetal-experiment.dylib
echo "== undefined symbols (imports) of sbmetal-experiment =="
llvm-nm -u "$L" 2>/dev/null | head -40
echo
echo "== does it import os_log? =="
llvm-nm -u "$L" 2>/dev/null | grep -iE "os_log|printf|fprintf|puts|write" | head -10
echo
echo "== same question for the library that DOES print (sb26) =="
llvm-nm -u /root/star26/s44/work/root/lib/libannibale-sb26.dylib 2>/dev/null | grep -iE "os_log|printf" | head -10
