#!/bin/bash
D=/root/star26/hackios-xnu-userland/userland/src
echo "== annsh source =="
find "$D" -name "*annsh*" 2>/dev/null | head
echo
F=$(find "$D" -name "*annsh*" 2>/dev/null | head -1)
if [ -n "$F" ]; then
  echo "== registered command names =="
  grep -nE '"[a-z][a-z_-]{2,14}"' "$F" | head -40
fi
