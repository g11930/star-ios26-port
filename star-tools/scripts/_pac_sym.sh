#!/bin/bash
F=/root/star26/star-native/osfmk/arm64/sleh.c
echo "=== PAC 相关符号行号 ==="
grep -n -i -E 'pac_patch|pac_patch_page|pac_patch_encode|pac_patch_enabled|handle_uncategorized|pac: |ptrauth|PACIZA|AUTIZA|RETAA|RETAB|BRAA|BLRAA|LDRA' "$F" | head -80
echo
echo "=== 文件行数 ==="; wc -l "$F"
