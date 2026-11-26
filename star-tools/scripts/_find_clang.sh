#!/bash
echo "===== 找 xnu-clang ====="
for p in "$HOME/theos/toolchain/linux/iphone/bin" "$HOME/theos/bin" /root/theos/toolchain/linux/iphone/bin; do
  [ -d "$p" ] && ls "$p" | head -8
done
command -v clang; clang --version 2>/dev/null | head -2
echo "--- 已编译好的 obj 里有无 dylib:"
ls -l /root/star26/hackios-xnu-userland/userland/obj/libannibale.dylib 2>/dev/null
</bash>
