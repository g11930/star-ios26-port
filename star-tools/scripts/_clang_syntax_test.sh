#!/bin/bash
SDK=/root/theos/sdks/iPhoneOS16.5.sdk
printf '#include <CoreFoundation/CoreFoundation.h>\nint main(){return 0;}\n' > /tmp/t.c
echo "=== sysroot exists? ==="; test -d "$SDK" && echo YES
/usr/bin/clang -target arm64-apple-ios16.5 -isysroot "$SDK" -fsyntax-only /tmp/t.c 2>&1 | head -20
echo "RC=${PIPESTATUS[0]}"
