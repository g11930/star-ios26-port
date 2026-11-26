#!/bin/bash
R=/root/star26/star-native
echo "=== who assigns vinfo fields ==="
grep -rn "vinfo\.v_baseaddr\|vinfo\.v_physaddr\|vinfo\.v_width\|vinfo\.v_rowbytes" "$R/osfmk" "$R/pexpert" "$R/iokit" 2>/dev/null | grep -v "\.bak" | grep "=" | head -20
echo
echo "=== vinfo declaration ==="
grep -rn "struct vc_info vinfo" "$R" 2>/dev/null | grep -v "\.bak" | head
