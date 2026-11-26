#!/bin/bash
set -u
M=/root/star26/hackios-xnu-kernel/xnu-deps/build/mesa/mesa-26.2.5
echo "== nir_instr_type enum =="
grep -rn "nir_instr_type_alu," $M/src/compiler/nir/nir.h | head -3
awk '/typedef enum \{/{f=1} f' $M/src/compiler/nir/nir.h | grep -n -m1 -A25 "nir_instr_type_alu" | head -30
echo
echo "== air_half_test: instruction type / expectations =="
grep -n "instruction type\|nir_instr_type\|CHECK(strstr" $M/src/compiler/air/air_half_test.c | head -40
echo
echo "== air dir listing =="
ls -la $M/src/compiler/air/ | head -40
