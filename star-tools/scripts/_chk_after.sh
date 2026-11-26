#!/bin/bash
F=/root/star26/star-native/bsd/dev/star/annibale_input.c
echo "=== all printf( occurrences ==="
grep -n "printf(" "$F"
echo
echo "=== annibale_tl occurrences ==="
grep -n "annibale_tl" "$F"
echo
echo "=== patched function body ==="
sed -n '/annibale_tl(const char \*format, \.\.\.)$/,/^}/p' "$F"
echo
echo "=== who else declares annibale_tl ==="
grep -rn "annibale_tl" /root/star26/star-native --include=*.h --include=*.c --include=*.cpp --include=*.inc 2>/dev/null | grep -v "\.bak" | grep -v "annibale_input.c"
