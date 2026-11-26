#!/bash
F=/root/sys-root/System/Library/PrivateFrameworks/IOMobileFramebuffer.framework
echo "===== 框架内容 ====="
find $F -maxdepth 2 -type f -printf '%s %p\n' 2>/dev/null | head -10
echo
BIN=$(find $F -maxdepth 1 -type f | head -1)
echo "binary = $BIN"
echo
echo "===== 里面的类名 / 匹配字符串 ====="
strings -n 4 "$BIN" | grep -iE "Apple(CLCD|M2CLCD|H1CLCD)|IOMobileFramebuffer|disp0|IOFramebuffer|AppleDisplay" | sort -u | head -40
echo
echo "===== 导入的 IOService* / 匹配符号 ====="
llvm-objdump --macho --syms "$BIN" 2>/dev/null | grep -iE "IOServiceMatching|MatchingService|IOServiceOpen|IOMobileFramebuffer" | head -20
echo "===== DONE ====="
</bash>
