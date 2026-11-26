#!/bin/bash
K=/root/star26/hackios-xnu-kernel
echo "=== docs mentioning black ==="
grep -rn -i 'black' $K/docs/*.md 2>/dev/null | grep -i 'icon\|texture\|image' | head -12
echo "=== docs mentioning icons ==="
grep -rln -i 'icon' $K/docs/*.md 2>/dev/null | head
echo "=== any render6x docs ==="
ls $K/docs | tail -8
</>
