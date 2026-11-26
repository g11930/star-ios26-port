#!/bin/bash
cd /mnt/d/桌面/star26-deps/scripts
N=164 bash ./make-s135.sh 2>&1 | grep 'boot.img' | tail -1
sed 's/TAG=s131/TAG=s164/' _s131_flash.sh > _s164_flash.sh
python3 _patch_wait.py _s164_flash.sh
bash _s164_flash.sh
</>
