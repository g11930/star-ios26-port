#!/bash
NEW=/root/star26/hackios-xnu-userland/userland/obj/libannibale.dylib
echo "===== 提取 s111 里的旧库（release 版）====="
python3 - <<'PY'
import sys, os
sys.path.insert(0, "/root/star-build/tools/apfs")
import apfs
c = apfs.Container("/root/star26/s111/root2.apfs")
v = c.volumes()[0]
ino = v.lookup("/lib/libannibale.dylib")
ino = ino[0] if isinstance(ino, tuple) else ino
data = v.inode(ino).contents()
open("/root/old-libannibale.dylib","wb").write(data)
print("old lib", len(data))
PY
OLD=/root/old-libannibale.dylib

for f in "$OLD" "$NEW"; do
  echo "=================== $f"
  ls -l "$f"
  echo "--- header:"
  llvm-objdump --macho -h "$f" 2>/dev/null | head -10
  echo "--- build version / codesig:"
  llvm-objdump --macho --private-headers "$f" 2>/dev/null | grep -E "platform|sdk|minos|LC_CODE_SIGNATURE|LC_BUILD_VERSION|LC_VERSION_MIN" | head -6
  echo "--- init funcs:"
  llvm-objdump --macho --private-headers "$f" 2>/dev/null | grep -A2 "LC_ROUTINES\|__mod_init" | head -6
  echo "--- 依赖:"
  llvm-objdump --macho --private-headers "$f" 2>/dev/null | grep -E "name /|name @|name usr" | head -8
done
echo "===== DONE ====="
</bash>
