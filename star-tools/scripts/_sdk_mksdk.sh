#!/bin/bash
# Build a minimal iOS26 SDK from /root/sys-root (headers) + theos 16.5 (tbd stubs)
set -e
SDK=/root/star26/hackios-xnu-userland/xnu-deps/26/sdk/iPhoneOS.sdk
mkdir -p "$SDK/usr"
# System + Library from sys-root via symlink
for d in System Library; do
  [ -e "$SDK/$d" ] || ln -s "/root/sys-root/$d" "$SDK/$d"
done
# usr/lib from theos 16.5 (tbd stubs for linking) via symlink
[ -e "$SDK/usr/lib" ] || ln -s /root/theos/sdks/iPhoneOS16.5.sdk/usr/lib "$SDK/usr/lib"
# usr/include if sys-root has it
[ -d /root/sys-root/usr/include ] && [ ! -e "$SDK/usr/include" ] && ln -s /root/sys-root/usr/include "$SDK/usr/include" || true
echo "=== SDK layout ==="
ls -la "$SDK" | head
ls -la "$SDK/usr" | head
echo "=== header check ==="
ls "$SDK/System/Library/Frameworks/CoreFoundation.framework/Headers/CoreFoundation.h" >/dev/null && echo CF OK
ls "$SDK/usr/lib/libobjc.tbd" >/dev/null && echo objc OK
ls "$SDK/System/Library/Frameworks/Metal.framework/Headers/Metal.h" >/dev/null && echo Metal OK
