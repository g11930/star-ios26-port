import sys
p = sys.argv[1]
s = open(p).read()
OLD1 = 'case "$p" in *xnuloader*) timeout 15 "$F" -s xnuloader reboot >/dev/null 2>&1; sleep 10 ;; esac'
NEW1 = ('waitadb () { for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30; do '
        'ad=$("$A" devices 2>/dev/null | tr -d "\\r" | grep -c "device$"); [ "$ad" -ge 1 ] && return 0; sleep 4; done; return 1; }\n'
        'case "$p" in *xnuloader*) timeout 15 "$F" -s xnuloader reboot >/dev/null 2>&1; waitadb ;; esac')
OLD2 = '[ "$ad" -lt 1 ] && { echo "ABORT: no android"; exit 2; }'
NEW2 = 'waitadb || { echo "ABORT: no android"; exit 2; }'
if OLD1 in s:
    s = s.replace(OLD1, NEW1)
if OLD2 in s:
    s = s.replace(OLD2, NEW2)
open(p, 'w').write(s)
print("patched" if (NEW1 in s or NEW2 in s) else "NO MATCH")
