#!/bin/bash
U=/root/star26/hackios-xnu-userland/userland/src
echo "=== who prints 'render pipelines' ==="
grep -rn 'render pipelines' $U 2>/dev/null | head -5
echo "=== shim source dirs ==="
ls $U
echo "=== files with MTLRenderPipeline ==="
grep -rln 'newRenderPipelineState' $U 2>/dev/null | head -8
</>
