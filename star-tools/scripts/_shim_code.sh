#!/bin/bash
F=/root/star26/hackios-xnu-kernel/tools/userland-driver/annibalemetal.m
echo "=== size ==="; wc -l $F
echo "=== render pipelines log ==="
grep -n 'render pipelines' $F | head -3
echo "=== pipeline creation ==="
grep -n 'newRenderPipelineState\|build_pipeline\|glLinkProgram\|glShaderSource' $F | head -14
echo "=== existing cache ==="
grep -n -i 'cache' $F | head -12
</
