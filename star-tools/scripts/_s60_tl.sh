#!/bin/bash
# s60 timeline: launchd exit, SpringBoard/backboardd spawn, boot tasks order
grep -E 'P28EXIT|WILL_SPAWN|Successfully spawned|Doing boot task|EXECDBG: loading /(usr/libexec/backboardd|System/Library/CoreServices/SpringBoard|usr/libexec/logd|sbin/launchd)|application com\.apple\.SpringBoard|\[  [0-9]+\]' /tmp/s60.txt | grep -vE 'logdtrace|ufs:' | head -60
