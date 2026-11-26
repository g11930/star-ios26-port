#!/bin/bash
OUT=/mnt/c/ios26/k90_runningboard_fix.out
: > "$OUT"
e(){ echo "$@" >> "$OUT"; }
W=/root/star26/warsaw-ref
S=/root/star26/hackios-xnu-userland

e "########## 1) K90 refs: runningboard / RBS / FBSystemShellInitialize ##########"
grep -rln "FBSystemShellInitialize\|runningboard\|RBSAssertion\|RunningBoardServices\|RBSProcess" "$W" 2>/dev/null | head -40 >> "$OUT"

e ""
e "########## 2) star userland: same terms ##########"
grep -rln "FBSystemShellInitialize\|runningboard\|RBSAssertion\|RunningBoardServices\|RBSProcess" "$S" 2>/dev/null | head -40 >> "$OUT"

e ""
e "########## 3) K90 docs: synchronous XPC / 4s / SpringBoard abort ##########"
grep -rn -i "synchronous XPC\|sync xpc\|4 s\|4s\|abort SpringBoard\|NULL.*abort\|decode.*dictionary\|handshake" "$W/docs" 2>/dev/null | head -40 >> "$OUT"

e ""
e "########## 4) K90 inject_sb26: runningboard / assertion / xpc hooks ##########"
grep -n -i "runningboard\|RBS\|assertion\|xpc\|FBSystem" "$W/userland/src/inject_sb26.c" 2>/dev/null | head -60 >> "$OUT"

e ""
e "########## 5) K90 userland source list ##########"
find "$W/userland/src" -type f -name '*.c' -o -name '*.m' 2>/dev/null | sort >> "$OUT"

e ""
e "########## 6) star userland source list ##########"
find "$S/userland/src" -type f \( -name '*.c' -o -name '*.m' \) 2>/dev/null | sort >> "$OUT"

e ""
e "########## DONE ##########"
echo "OK $(wc -c < "$OUT") bytes"
