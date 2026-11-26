#!/bin/bash
cd /root/star26/star-native
git --no-pager log --date=iso --pretty='%h %ad %s' -12
echo "=== HEAD date ==="
git show -s --date=iso --pretty='%h %ad' HEAD