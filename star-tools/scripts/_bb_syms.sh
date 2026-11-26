#!/bash
cd /root || exit 1
echo "===== backboardd 导入的 IOMobileFramebuffer* 符号 ====="
llvm-objdump --macho --syms backboardd.bin 2>/dev/null | grep -i "IOMobileFramebuffer" | head -30
echo
echo "===== backboardd 导入的 BKDisplay / CLCD 相关符号 ====="
llvm-objdump --macho --syms backboardd.bin 2>/dev/null | grep -E "BKDisplay|CLCD|IOFramebuffer" | head -30
echo
echo "===== SpringBoard 导入的 Framebuffer 符号 ====="
llvm-objdump --macho --syms /root/sys-root/System/Library/CoreServices/SpringBoard.app/SpringBoard 2>/dev/null | grep -i "Framebuffer" | head -10
</bash>
