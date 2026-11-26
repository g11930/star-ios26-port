#!/bin/bash
# 用页面实际发出的命令形态，在设备上逐条验证 WebUI 按钮背后的路径。
A=/mnt/d/桌面/adb-fastboot/adb.exe
M=/data/adb/modules/starfs

run_one() {
    local title="$1"; shift
    local cmd="$*"
    echo "########## $title"
    echo "\$ $cmd"
    "$A" shell "su -c '$cmd'" 2>&1 | tr -d '\r'
    echo
}

echo "=== [$(date +%T)] device ==="
"$A" devices 2>&1 | tr -d '\r'

echo
echo "=== module dir listing (as the page sees it) ==="
"$A" shell "su -c 'ls -l $M/webroot/'" 2>&1 | tr -d '\r'

run_one "按钮：环境自检 root" "sh $M/webroot/starfs-run.sh root"

echo "########## 按钮：GPT 分区表 (--tsv，页面用它是为了拿 7 列)"
echo "\$ sh $M/webroot/starfs-run.sh gpt list --tsv"
T=$("$A" shell "su -c 'sh $M/webroot/starfs-run.sh gpt list --tsv'" 2>&1 | tr -d '\r')
printf '%s\n' "$T" | head -8
echo "--- 列数统计（页面要求 >= 7 才会渲染该行）---"
printf '%s\n' "$T" | awk -F'\t' 'NF>0 { printf "line %d: %d 列  idx=%s name=%s\n", NR, NF, $1, $2 }' | head -12
echo

run_one "按钮：APFS 用量" "sh $M/webroot/starfs-run.sh usage"
run_one "预览：darwin 16G（按钮流程第一步）" "sh $M/webroot/starfs-run.sh gpt plan 38 --size 16G"
run_one "按钮：日志目录" "sh $M/webroot/open-dir.sh ls"
run_one "按钮：可用打开方式" "sh $M/webroot/open-dir.sh list"
run_one "按钮：loader 信息" "sh $M/webroot/boot-loader.sh info"
