#!/bin/bash
R=/root/g11930-ref/xnu/files/bsd
ls $R 2>/dev/null | head -30
echo "=== touch-ish files ==="
ls -l $R/*fts* $R/*touch* $R/*input* 2>/dev/null
echo "=== dev/star or redwood dir ==="
ls -d $R/dev/* 2>/dev/null | head
ls $R/dev/redwood 2>/dev/null | head -30
</