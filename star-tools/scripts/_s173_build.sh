#!/bin/bash
cd /mnt/d/桌面/star26-deps/scripts
N=173 bash ./make-s139.sh 2>&1 | grep -E 'boot.img' | tail -1
</>
