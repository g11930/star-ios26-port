#!/bin/bash
set +e
K=/root/star26/star-native/bsd/kern/kern_exec.c
echo "########## 1. posix_spawn definition + local vars ##########"
sed -n '4430,4475p' "$K"
echo "########## 2. spawn_validate_persona call site ##########"
sed -n '4725,4760p' "$K"
echo "########## 3. exec path / image setup ##########"
grep -n "psfaa_path\|exec_applog_path\|ip_px_persona\|px_persona\|psp_path\|psfa->" "$K" | sed -n '1,60p'
echo "########## 4. spawn_persona_adopt call site ##########"
sed -n '5175,5205p' "$K"
echo "########## 5. bad: labels / error exits in posix_spawn ##########"
awk 'NR>=4430 && NR<=5300 && /^bad:|^bad[0-9]*:|^ *goto bad|error = |goto out/' "$K" | head -60
echo "########## 6. IOLog availability in kern_exec.c ##########"
grep -n "IOLog\|loader_log_line\|STAR0\|star_trace" "$K" | head -30
