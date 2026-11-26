#!/bin/bash
D=/root/star26/hackios-xnu-kernel/docs/metal.md
echo "== size =="
wc -l "$D"
echo "== section headings =="
grep -nE "^#+ |^[0-9]+\.|^[0-9]+\.[0-9]+" "$D" | head -60
