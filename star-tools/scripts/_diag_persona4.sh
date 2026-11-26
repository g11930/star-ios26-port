#!/bin/bash
set +e
F=/tmp/logdump_cur.bin
echo "=== who calls kpersona_find_by_type (syscall path) ==="
grep -rn "kpersona_find_by_type\|PERSONA_FIND_BY_TYPE\|kpersona_find" /root/star26/star-native/bsd/kern/sys_persona.c | head -20
echo "=== does dada patch touch sys_persona.c / persona_find_by_type? ==="
grep -n "persona_find_by_type\|sys_persona.c\|kpersona_find" /root/ref/dada/kernel/xnu-12377.121.6-dada.patch | head -20
echo "=== xpcproxy exit 0 but no target exec: check next EXECDBG after each xpcproxy ==="
strings -a "$F" | grep -nE "EXECDBG: loading /usr/libexec/(xpcproxy|cfprefsd|configd|securityd|lsd|.*d) " | grep -v xpcproxy | head -20
echo "=== count xpcproxy load vs real daemon exec ==="
echo -n "xpcproxy loads: "; strings -a "$F" | grep -c "EXECDBG: loading /usr/libexec/xpcproxy"
echo -n "cfprefsd execs: "; strings -a "$F" | grep -c "EXECDBG: loading /usr/libexec/cfprefsd"
echo -n "configd execs: "; strings -a "$F" | grep -c "EXECDBG: loading /usr/libexec/configd"
echo -n "securityd execs: "; strings -a "$F" | grep -c "EXECDBG: loading /usr/libexec/securityd"
