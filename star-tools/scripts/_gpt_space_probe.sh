#!/bin/bash
A=/mnt/d/桌面/adb-fastboot/adb.exe
M=/data/adb/modules/starfs
R="sh $M/webroot/starfs-run.sh"

echo "=== 1. 全表（index name first last bytes）"
"$A" shell "su -c \"$R gpt list --tsv\"" 2>&1 | tr -d '\r' > /mnt/c/ios26/tsv_now.txt
cat /mnt/c/ios26/tsv_now.txt | awk -F'\t' '{printf "%3s  %-16s %12s %12s %10.2fGB\n", $1,$2,$3,$4,$6/1073741824}'

echo
echo "=== 2. 按 LBA 排序后的空隙（>=1MiB 才打印）"
sort -t$'\t' -k3 -n /mnt/c/ios26/tsv_now.txt | awk -F'\t' '
BEGIN { prev=6 }
{ first=$3; gap=first-prev; if (gap>256) printf "  gap %12d..%12d  %8.2f MiB  (在 %s 之前)\n", prev, first-1, gap*4096/1048576, $2; prev=$4+1 }
END { printf "  末尾 最后一个分区结束于 %d，usable 到 61844474\n", prev-1 }
'

echo
echo "=== 3. darwin_var (sda37) 是否为空：抽 3 个位置看非零字节"
"$A" shell "su -c 'for off in 0 1048576 8388608; do n=\$(dd if=/dev/block/sda37 bs=4096 skip=\$((off/4096)) count=16 2>/dev/null | tr -d \"\\\\000\" | wc -c); echo \"  offset \$off : 非零字节 \$n\"; done'" 2>&1 | tr -d '\r'

echo
echo "=== 4. darwin_var 前 64 字节（魔数）"
"$A" shell "su -c 'dd if=/dev/block/sda37 bs=64 count=1 2>/dev/null | od -An -tx1 -c | head -6'" 2>&1 | tr -d '\r'

echo
echo "=== 5. darwin (sda38) NXSB 关键字段"
"$A" shell "su -c 'dd if=/dev/block/sda38 bs=4096 count=1 2>/dev/null | od -An -tx1 -j32 -N40'" 2>&1 | tr -d '\r'
echo "  (offset 32 应为 NXSB；36=nx_block_size, 40=nx_block_count)"
