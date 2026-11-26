#!/bin/bash
U=/root/star26/hackios-xnu-userland/userland
echo "--- metal shim sources ---"
grep -rln 'MTLPixelFormat\|pixelFormat' $U/src 2>/dev/null | head -12
echo "--- format tables ---"
grep -rn 'BGRA8Unorm_sRGB\|RGBA16Float\|BGR10A2' $U/src 2>/dev/null | head -12
</