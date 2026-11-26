#!/bin/bash
cd /mnt/d/桌面/star26-deps/scripts
N=167 bash ./make-s135.sh 2>&1 | grep 'boot.img' | tail -1
sed 's/TAG=s131/TAG=s167/' _s131_flash.sh > _s167_flash.sh
python3 _patch_wait.py _s167_flash.sh
bash _s167_flash.sh
</>
