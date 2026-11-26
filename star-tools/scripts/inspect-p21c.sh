#!/bin/bash
R=/root/star26/kbuild/xnu-12377.121.6
K=/root/star26/hackios-xnu-kernel
echo "=== bsd_init annibale calls ==="
grep -n 'annibale_' $R/bsd/kern/bsd_init.c | head -30
echo "=== bsd_init around 1010-1035 ==="
sed -n '1005,1035p' $R/bsd/kern/bsd_init.c
echo "=== work tree copies ==="
ls -l $K/xnu/files/iokit/Kernel/AnnibaleGPU.cpp $K/xnu/files/bsd/dev/annibale/annibale_gpu_dispatch.c 2>&1
echo "=== md5 compare ==="
md5sum $R/iokit/Kernel/AnnibaleGPU.cpp $K/xnu/files/iokit/Kernel/AnnibaleGPU.cpp 2>&1
md5sum $R/bsd/dev/annibale/annibale_gpu_dispatch.c $K/xnu/files/bsd/dev/annibale/annibale_gpu_dispatch.c 2>&1
echo "=== kbuild bsd_init vs worktree ==="
md5sum $R/bsd/kern/bsd_init.c $K/xnu/files/bsd/kern/bsd_init.c 2>&1
