#!/bash
cd /root || exit 1
echo "===== 工具检查 ====="
for t in llvm-objdump objdump otool gobjdump; do
  p=$(command -v $t 2>/dev/null)
  echo "$t: ${p:-none}"
done
echo
echo "===== backboardd 里 framebuffer 符号引用 ====="
if command -v llvm-objdump >/dev/null 2>&1; then
  llvm-objdump -d --macho backboardd.bin 2>/dev/null | grep -n "IOMobileFramebuffer" | head -10
fi
