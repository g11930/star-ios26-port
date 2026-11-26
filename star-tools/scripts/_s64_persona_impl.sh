#!/bin/bash
K=/root/star26/star-native/bsd/kern/kern_persona.c
echo "########## persona_find_all impl ##########"
awk '/^persona_find_all\(/,/^}/' "$K" | head -60
echo
echo "########## line 860-880 (is_system check) ##########"
sed -n '855,880p' "$K"
echo
echo "########## line 905-935 (the stub) ##########"
sed -n '905,940p' "$K"
echo
echo "########## persona_lookup impl ##########"
awk '/^persona_lookup\(/,/^}/' "$K" | head -30
echo
echo "########## all_personas list decl & insert ##########"
grep -n "all_personas\|LIST_INSERT_HEAD\|TAILQ_INSERT" "$K" | head -20
