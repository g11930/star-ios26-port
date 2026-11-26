#!/bin/bash
TC=/root/theos/toolchain/linux/iphone/bin
SDK=/root/theos/sdks/iPhoneOS16.5.sdk
echo "=== theos clang version ==="
$TC/clang --version 2>&1 | head -3
cat > /tmp/t_ptrauth.c <<'EOF'
#ifndef __has_feature
#define __has_feature(x) 0
#endif
#if __has_feature(ptrauth_calls)
int has_ptrauth = 1;
#else
int has_ptrauth = 0;
#endif
int foo(int x){return x+1;}
EOF
for flag in "-arch arm64e -isysroot $SDK" "-target arm64e-apple-ios16.5 -isysroot $SDK" "-arch arm64e -isysroot $SDK -fptrauth-calls"; do
  echo "=== flags: $flag ==="
  $TC/clang $flag -c /tmp/t_ptrauth.c -o /tmp/t_ptrauth.o 2>&1 | head -5
  if [ -f /tmp/t_ptrauth.o ]; then
    python3 - /tmp/t_ptrauth.o <<'PY'
import struct,sys
d=open(sys.argv[1],'rb').read()
if d[:4]==b'\xcf\xfa\xed\xfe':
    cpu,sub=struct.unpack_from('<ii',d,4)
    print(f'  cpusubtype={sub&0xffffffff:#x}')
else: print(f'  not macho {d[:4].hex()}')
PY
    # check has_ptrauth value in data
    $TC/clang $flag -S -emit-llvm /tmp/t_ptrauth.c -o - 2>/dev/null | grep -m1 'has_ptrauth' 
    rm -f /tmp/t_ptrauth.o
  fi
done
