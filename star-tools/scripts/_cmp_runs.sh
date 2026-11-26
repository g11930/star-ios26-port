#!/bin/bash
for f in s143 s144 s145 s146 s147 s148 s149 s150; do
  p=/tmp/$f.txt
  [ -f "$p" ] || continue
  sw=$(grep -ac 'swap ' "$p")
  cc=$(grep -ac 'needs the compiler library' "$p")
  rg=$(grep -a 'registration completed device' "$p" | head -1)
  echo "$f  swaps=$sw  compiler_needed=$cc  $rg"
done
</