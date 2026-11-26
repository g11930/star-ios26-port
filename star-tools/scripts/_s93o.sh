#!/bin/bash
U=/root/star26/hackios-xnu-userland
echo "=== A. sb_metal_experiment.m 文件信息 ==="
ls -l $U/userland/src/inject/sb_metal_experiment.m
echo
echo "=== B. 该文件里 Accelerator/属性相关行 ==="
grep -n 'Accelerator\|setProperty\|kIOAccelerator\|IOAccelerator\|metal\|Metal\|sgx\|SGX' $U/userland/src/inject/sb_metal_experiment.m | head -60
echo
echo "=== C. inject 目录全清单 ==="
ls -l $U/userland/src/inject/
echo
echo "=== D. 所有 inject 源里搜 Accelerator 属性关键字 ==="
grep -rn 'AcceleratorPlugin\|kAcceleratorPluginNameKey\|kAcceleratorPluginClassNameKey' $U 2>/dev/null | head -30
echo
echo "=== E. obj 里最近构建的 dylib ==="
ls -lt $U/userland/obj/ 2>/dev/null | head -25
echo
echo "=== F. 最近日志文件 ==="
ls -lt /root/star26/*.log /root/star26/logs/* /root/star26-deps/*.log 2>/dev/null | head -20
find /root/star26 -maxdepth 2 -name '*.log' -newermt '2026-11-16' 2>/dev/null | head -20
echo "=== DONE ==="
