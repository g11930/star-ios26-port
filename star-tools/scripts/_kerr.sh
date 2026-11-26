#!/bin/bash
grep -n -B12 'linker command failed' /tmp/kb12.log | head -24