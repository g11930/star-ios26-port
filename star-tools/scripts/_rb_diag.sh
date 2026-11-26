#!/bin/bash
OUT=/mnt/c/ios26/rb_diag.out
: > "$OUT"
e(){ echo "$@" >> "$OUT"; }
L=/mnt/c/ios26/s94-live3.bin

e "########## 1) runningboardd: ALL assertion/grant/domain lines (first 40) ##########"
grep -a "runningboardd\[" "$L" | tr -d '\0' | grep -iE "assertion|grant|domain|FBSystem|shell|pid 32|target" | head -40 >> "$OUT"

e ""
e "########## 2) runningboardd: any ERROR / reject / deny / fail ##########"
grep -a "runningboardd\[" "$L" | tr -d '\0' | grep -iE "error|reject|deny|denied|fail|invalid|corrupt|unable|unknown|no such" | head -40 >> "$OUT"

e ""
e "########## 3) SpringBoard handshake / assertion full sequence ##########"
grep -a "SpringBoard\[32" "$L" | tr -d '\0' | grep -iE "handshake|assertion|runningboard|RBS|FBSystem|attempt" >> "$OUT"

e ""
e "########## 4) any RBS assertion descriptor / FBSystemShell anywhere ##########"
grep -a "FBSystemShellInitialize\|RBSAssertionDescriptor\|FBSystemShell" "$L" | tr -d '\0' | head -30 >> "$OUT"

e ""
e "########## 5) handshake succeeded lines (which services) ##########"
grep -a "Handshake succeeded\|handshake succeeded\|handshake request" "$L" | tr -d '\0' | head -40 >> "$OUT"

e ""
e "########## 6) entitlement / seccode / audit errors near startup ##########"
grep -a -iE "SecTask|entitlement|SecCode|audit token|audit_token|csops|code sign" "$L" | tr -d '\0' | grep -iE "error|fail|invalid|deny|null|missing" | head -40 >> "$OUT"

e ""
e "########## 7) K90 normal: runningboard assertion in v37 log ##########"
K=/root/star26/warsaw-ref/docs/v37/log-tail.txt
grep -a -i "runningboard\|assertion\|FBSystemShell" "$K" 2>/dev/null | head -30 >> "$OUT"

e ""
e "########## DONE ##########"
echo "OK $(wc -c < "$OUT") bytes"
