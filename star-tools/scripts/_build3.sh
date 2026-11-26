#!/bin/bash
F=/root/star26/star-native/bsd/dev/star/annibale_goodix.c
sed -i 's/goodix_log(/goodix_trace(/g' $F
python3 - <<'PY'
p='/root/star26/star-native/bsd/dev/star/annibale_goodix.c'
s=open(p).read()
# the helper itself must keep the new name consistent
s=s.replace('static void\ngoodix_trace(const char *format, ...) __printflike(1, 2);\n\nstatic void\ngoodix_trace(const char *format, ...)','static void\ngoodix_trace(const char *format, ...) __printflike(1, 2);\n\nstatic void\ngoodix_trace(const char *format, ...)')
open(p,'w').write(s)
print('trace helper:', s.count('goodix_trace('))
PY
bash /mnt/d/桌面/star26-deps/scripts/build-star-native.sh >/dev/null 2>&1
echo "errors: $(grep -c 'error:' /mnt/c/ios26/star-native-build.log)"
grep 'error:' /mnt/c/ios26/star-native-build.log | head -5
tail -2 /mnt/c/ios26/star-native-build.log
</>
