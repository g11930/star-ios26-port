#!/bash
echo "===== 常量拼装指令上下文 ====="
llvm-objdump --macho -d /root/old-libannibale.dylib 2>/dev/null | sed -n '/42d0:/,/4310:/p' | head -30
echo
echo "===== 所有 movk x9 / movz x9 ====="
llvm-objdump --macho -d /root/old-libannibale.dylib 2>/dev/null | grep -nE "\bx9\b" | grep -E "movz|movk" | head -20
echo "===== DONE ====="
</bash>
