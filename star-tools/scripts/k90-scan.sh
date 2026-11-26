#!/bin/bash
cd /root/star26/hackios-redmi-k90-annibale || exit 1
for k in launchd load_init_program execve macho_loader 'boot progress' console; do
    echo "===== $k"
    git grep -l -i -F "$k" origin/main -- docs | head -12
done
echo "===== 文档总数"
git ls-tree -r --name-only origin/main -- docs | wc -l
