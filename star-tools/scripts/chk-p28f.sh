#!/bin/bash
S=/root/star26/kbuild/xnu-12377.121.6/osfmk/arm64/sleh.c
echo "--- source truth ---"
ls -li --time-style=full-iso "$S"
md5sum "$S"
grep -c P28FAULT "$S"
sed -n "2266,2280p" "$S"
echo "--- all sleh.c on disk ---"
find / -name sleh.c -not -path "*/BUILD/*" 2>/dev/null | head
echo "--- all sleh.o ---"
find /root -name "sleh.o" 2>/dev/null | head
