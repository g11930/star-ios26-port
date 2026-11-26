#!/bin/bash
echo "########## 1. persona_type_t enum ##########"
sed -n '1,80p' /root/star26/star-native/bsd/sys/persona.h
echo
echo "########## 2. who creates SYSTEM / SYSTEM_PROXY persona in kernel ##########"
grep -rn "PERSONA_SYSTEM_PROXY\|PERSONA_SYSTEM\b\|persona_find_by_type" /root/star26/star-native/bsd/ /root/star26/star-native/osfmk/ 2>/dev/null | grep -v "\.o:" | head -25
echo
echo "########## 3. persona_find_by_type impl ##########"
awk '/^persona_find_by_type/,/^}/' /root/star26/star-native/bsd/kern/kern_persona.c | head -40
