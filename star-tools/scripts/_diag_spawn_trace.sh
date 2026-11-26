#!/bin/bash
set +e
K=/root/star26/star-native/bsd/kern/kern_exec.c
echo "########## 1. existing STARX/star_trace/snprintf/loader_log_line in kern_exec.c ##########"
grep -n "STARX\|star_trace\|star_log\|loader_log_line\|snprintf\|extern.*IOLog" "$K" | head -40
echo "########## 2. star_trace definition body ##########"
grep -n "static.*star_trace\|star_trace(" "$K" | head -5
echo "########## 3. bad: label locations in posix_spawn ##########"
grep -n "^bad:\|^ *bad:\|goto bad" "$K" | head -40
echo "########## 4. posix_spawn header / args / path copyin ##########"
sed -n '4540,4620p' "$K"
echo "########## 5. where exec path string lives (uap->path / px_args) ##########"
grep -nE "uap->|args\.path|px_args\.|pathp|exec_path|ip_px_" "$K" | sed -n '1,50p'
