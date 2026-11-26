#!/bin/bash
# Probe which oem commands the xnuloader fastboot supports (read-only probes).
FB=/d/桌面/adb-fastboot/fastboot.exe
run() {
  echo "--- $* ---"
  timeout 12 "$FB" "$@" 2>&1 | tr -d '\r' | head -6
}
run getvar result
run getvar var-status
run getvar is-userspace
run oem help
run oem cat /private/var/mobile/Library/Logs/CrashReporter
run oem ls /private/var/mobile/Library/Logs/CrashReporter
