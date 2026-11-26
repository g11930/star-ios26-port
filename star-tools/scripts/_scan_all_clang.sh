#!/bin/bash
echo "=== all clang binaries in known toolchain roots ==="
for root in /usr/bin /usr/local/bin /root/theos/toolchain /root/star26/hackios-xnu-kernel/xnu-deps /root/star26/hackios-xnu-userland/xnu-deps /root/star26/bin /opt /root/.local; do
  [ -d "$root" ] || continue
  find "$root" -type f \( -name 'clang' -o -name 'clang-1*' -o -name 'clang-2*' \) 2>/dev/null
done | sort -u | while read f; do
  v=$("$f" --version 2>/dev/null | head -1)
  echo "$f => $v"
done
echo "=== ptrauth-capable ones (test __has_feature) ==="
for f in /usr/bin/clang /usr/bin/clang-18 /root/theos/toolchain/linux/iphone/bin/clang /root/theos/toolchain/linux/iphone/bin/clang-11; do
  [ -x "$f" ] || continue
  cat > /tmp/pf.c <<'EOF'
#if __has_feature(ptrauth_calls)
int x=1;
#else
int x=0;
#endif
EOF
  "$f" -target arm64e-apple-ios16.5 -S -emit-llvm /tmp/pf.c -o /tmp/pf.ll 2>/dev/null
  val=$(grep -m1 '@x =' /tmp/pf.ll 2>/dev/null | grep -o 'i32 [01]' | grep -o '[01]')
  echo "$f => ptrauth=$val"
done
