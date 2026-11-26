#!/bin/bash
A=/mnt/d/桌面/adb-fastboot/adb.exe
M=/data/adb/modules/starfs
R="sh $M/webroot/starfs-run.sh"

say() { echo; echo "########## $*"; }

say "1. gpt list --tsv 是否纯净（不应有 device / usable / 表头 / 尾注）"
"$A" shell "su -c \"$R gpt list --tsv\"" 2>&1 | tr -d '\r' > /tmp/tsv.txt
echo "总行数: $(wc -l < /tmp/tsv.txt)"
echo "行首若不是数字即为污染行:"
awk -F'\t' 'NF<7 { printf "  POLLUTED: %s\n", $0 }' /tmp/tsv.txt
echo "字段数分布:"
awk -F'\t' '{print NF}' /tmp/tsv.txt | sort | uniq -c

say "2. verdict OK（37 darwin_var 缩到 4G，非 APFS 无容器下限）"
"$A" shell "su -c \"$R gpt plan 37 --size 4G\"" 2>&1 | tr -d '\r' | grep -E "verdict|result|delta|new "

say "3. verdict NOOP（38 darwin 保持 16G）"
"$A" shell "su -c \"$R gpt plan 38 --size 16G\"" 2>&1 | tr -d '\r' | grep -E "verdict|result|delta"

say "4. verdict REFUSED（38 darwin 扩到 20G，会压到 37）"
"$A" shell "su -c \"$R gpt plan 38 --size 20G\"" 2>&1 | tr -d '\r' | grep -E "verdict|result|FAIL"

say "5. REFUSED（36 hackios_sys 缩到 2G，小于容器 2.4G）"
"$A" shell "su -c \"$R gpt plan 36 --size 2G\"" 2>&1 | tr -d '\r' | grep -E "verdict|result|FAIL"

say "6. 页面实际带引号的调用形态（size/name 已加单引号）"
"$A" shell "su -c \"$R gpt plan 38 --size '16G'\"" 2>&1 | tr -d '\r' | grep -E "verdict|requested"

say "7. open-dir.sh ls 不带参数（应回退到 /sdcard/Download）"
"$A" shell "su -c \"sh $M/webroot/open-dir.sh ls\"" 2>&1 | tr -d '\r' | head -8

say "8. 分区表是否仍与操作前一致（所有测试都走只读路径）"
"$A" shell "su -c \"$R gpt list --tsv\"" 2>&1 | tr -d '\r' | awk -F'\t' 'NF>=7 && $2=="darwin" || $2=="darwin_var" || $2=="hackios_sys" {printf "  %s  first=%s last=%s\n",$2,$3,$4}'
