#!/bash
S=/root/star26/hackios-xnu-userland/userland/src
echo "===== inject 目录里的库源码 ====="
ls $S/inject 2>/dev/null | head -30
echo
echo "===== 谁在用户态碰 framebuffer / CAWindowServer / CADisplay ====="
grep -rln "IOMobileFramebuffer\|CAWindowServer\|CADisplay\|IOSurface" $S 2>/dev/null | head -15
echo
echo "===== 出现次数统计（按文件）====="
grep -rc "IOMobileFramebuffer\|CAWindowServer\|CADisplay" $S/inject 2>/dev/null | grep -v ":0" | head -10
echo "===== DONE ====="
</bash>
