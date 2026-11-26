#!/bin/bash
R=/root/star26/s111/work/rootbuild/root/lib
for f in $R/libannibale.dylib $R/libannibale-sb26.dylib; do
  echo "--- $(basename $f)"
  strings -n 4 "$f" | grep -n -i 'experiment\|sbmetal\|%s.dylib\|init_sb\|dlopen' | head -8
done
echo "=== injector: how it picks libs ==="
grep -n 'annibale\|inject.conf\|dlopen' /root/star26/hackios-xnu-userland/userland/src/inject/inject.c | sed -n '1,40p'
</