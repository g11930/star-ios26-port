#!/bin/bash
B=/root/star26/hackios-xnu-userland/userland
echo "== build.sh lines =="
wc -l "$B/build.sh"
echo "== signing / sb26 references =="
grep -nE "sign|ldid|codesign|LC_CODE_SIG|inject_sb26|sbmetal" "$B/build.sh" | head -30
echo "== any ldid/codesign on host =="
for t in ldid codesign rcodesign jtool2; do command -v $t >/dev/null 2>&1 && echo "have $t -> $(command -v $t)"; done
echo "== toolchain =="
ls -l /root/star-build/xnu-deps/host/bin/xcrun 2>/dev/null
