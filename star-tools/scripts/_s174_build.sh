#!/bin/bash
python3 /mnt/d/桌面/star26-deps/scripts/_rcjobs_clean.py
cd /mnt/d/桌面/star26-deps/scripts
N=174 bash ./make-s139.sh 2>&1 | grep -E 'boot.img' | tail -1
</>
