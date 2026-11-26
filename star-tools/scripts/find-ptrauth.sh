#!/bin/bash
echo "=== ptrauth.h candidates ==="
find /root/theos/sdks/iPhoneOS16.5.sdk -name 'ptrauth.h' 2>/dev/null
ls -la /usr/lib/llvm-18/lib/clang/18/include/ptrauth.h 2>/dev/null
find /root/sys-root -maxdepth 4 -name 'ptrauth.h' 2>/dev/null
echo "=== sdk include dirs ==="
ls /root/theos/sdks/iPhoneOS16.5.sdk/usr/include/ 2>/dev/null | head -8
ls -d /root/theos/sdks/iPhoneOS16.5.sdk/usr/lib/clang/* 2>/dev/null
