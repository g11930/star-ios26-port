#!/bin/bash
set -u
M=/root/star26/hackios-xnu-kernel/xnu-deps/build/mesa/mesa-26.2.5
echo "== nir_instr_type enum =="
grep -rn -A22 "typedef enum {" "$M/src/compiler/nir/nir.h" 2>/dev/null | grep -n "nir_instr_type" | head -30
echo "---- direct ----"
python3 - <<'PY'
import re
p="/root/star26/hackios-xnu-kernel/xnu-deps/build/mesa/mesa-26.2.5/src/compiler/nir/nir.h"
src=open(p,errors="replace").read()
i=src.find("typedef enum {")
while i!=-1:
    blk=src[i:i+1200]
    if "nir_instr_type_alu" in blk:
        # print enumerators in order
        body=blk[blk.find("{")+1:blk.find("}")]
        vals=[x.strip() for x in body.split(",") if x.strip()]
        for n,v in enumerate(vals):
            print(n, v.split("=")[0].strip())
        break
    i=src.find("typedef enum {", i+1)
PY
echo "== check_half_instructions source =="
sed -n '/check_half_instructions/,/^}/p' "$M/src/compiler/air/air_metal_lowering.inc" | head -80
