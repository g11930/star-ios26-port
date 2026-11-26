#!/bin/bash
# Test what cpusubtype clang18 emits for arm64e targets with various ptrauth flags.
cat > /tmp/t_ptrauth.c <<'EOF'
int foo(int x){return x+1;}
EOF
SDK=/root/theos/sdks/iPhoneOS16.5.sdk
check() {
  local desc="$1"; shift
  /usr/bin/clang "$@" -c /tmp/t_ptrauth.c -o /tmp/t_ptrauth.o 2>/dev/null
  if [ -f /tmp/t_ptrauth.o ]; then
    python3 - /tmp/t_ptrauth.o "$desc" <<'PY'
import struct,sys
d=open(sys.argv[1],'rb').read()
if d[:4]==b'\xcf\xfa\xed\xfe':
    cpu,sub=struct.unpack_from('<ii',d,4)
    print(f"{sys.argv[2]}: cpusubtype={sub&0xffffffff:#x}")
else:
    print(f"{sys.argv[2]}: not macho ({d[:4].hex()})")
PY
    rm -f /tmp/t_ptrauth.o
  else
    echo "$desc: COMPILE FAIL"
  fi
}
check "arm64e-apple-ios16.5" -target arm64e-apple-ios16.5 -isysroot "$SDK"
check "arm64e-apple-ios26" -target arm64e-apple-ios26.0 -isysroot "$SDK"
check "arm64e+ptrauth-inits" -target arm64e-apple-ios16.5 -isysroot "$SDK" -fptrauth-initsonsectionnames
check "arm64e+ptrauth-calls" -target arm64e-apple-ios16.5 -isysroot "$SDK" -fptrauth-calls
check "arm64e+ptrauth-ret" -target arm64e-apple-ios16.5 -isysroot "$SDK" -fptrauth-returns
