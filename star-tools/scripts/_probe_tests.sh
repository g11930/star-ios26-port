#!/bin/bash
D=/root/star26/hackios-xnu-userland/userland/src/tests
for f in metal_stubdev.m metal_props.c dlopen_test.c; do
  echo "==================== $f"
  sed -n '1,28p' "$D/$f"
  echo "---- key calls:"
  grep -nE "MTLCreateSystemDefaultDevice|MTLAddDevice|IOService|setProperties|dlopen" "$D/$f" | head -8
done
