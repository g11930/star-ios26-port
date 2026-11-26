#!/bin/bash
# AI 一键构建 s222 可开机镜像。
# 用法：bash star-tools/ai-build.sh
# 环境变量可覆盖（默认标准布局）：
#   TREE=/root/star26/star-native
#   BASELINE=/root/star26/baseline
#   OUT=/mnt/c/ios26/s222-boot.img
# 前置条件见仓库根目录 AI_BUILD.md 第 0、1 节；缺任一项即中止，不用占位符。
set -euo pipefail

# ---- 定位仓库与脚本目录（脚本位于 <repo>/star-tools/ai-build.sh）----
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$HERE/.." && pwd)"
SCRIPTS="$REPO/star-tools/scripts"
AIBUILD="$REPO/star-tools/ai-build"

TREE="${TREE:-/root/star26/star-native}"
BASELINE="${BASELINE:-/root/star26/baseline}"
OUT="${OUT:-/mnt/c/ios26/s222-boot.img}"

fail() { echo "ABORT: $*" >&2; exit 1; }

echo "=== [0/6] 前置条件核对 ==="
mkdir -p "$TREE" || fail "无法创建工作树 $TREE"
for d in "$SCRIPTS" "$AIBUILD" "$BASELINE/s207parts" "$BASELINE/s221parts"; do
  [ -d "$d" ] || fail "缺目录 $d（见 AI_BUILD.md 第 0/1 节）"
done
for t in python3 flex bison m4 llvm-nm llvm-objdump; do
  command -v "$t" >/dev/null 2>&1 || fail "缺工具 $t"
done
[ -x /usr/bin/llvm-nm ] || fail "缺 /usr/bin/llvm-nm（不要用 GNU nm）"
for p in loader.efi ramdisk rdimage memsize identity; do
  [ -f "$BASELINE/s221parts/$p" ] || fail "缺基线部件 $BASELINE/s221parts/$p"
done
[ -f "$BASELINE/s207parts/cmdline" ] || fail "缺 cmdline 基线"
[ -f "$BASELINE/s221parts/kernel" ] || fail "缺 s221 基线内核（单变量打包参照）"
echo "  前置条件 OK"

echo "=== [1/6] 建树：reset + stage1/2/7/7b ==="
python3 "$SCRIPTS/build-star-native-tree.py" --reset
python3 "$SCRIPTS/stage1-storage.py"
python3 "$SCRIPTS/stage2-display-probe.py"
python3 "$SCRIPTS/stage7-display-abi.py"
python3 "$SCRIPTS/stage7b-display-compat.py"

echo "=== [2/6] 应用 pager 补丁 + plain-auth 写回修复 ==="
( cd "$TREE" && git apply "$AIBUILD/native-4k-shared-region-slide.patch" ) \
  || fail "pager 补丁应用失败（树非干净基线？先跑 --reset）"
python3 "$AIBUILD/_s222_plainauth_fix.py" || fail "plain-auth 写回修复失败"

echo "=== [3/6] 编译 + stage-8 kalloc 回填闸门 ==="
bash "$SCRIPTS/build-star-native.sh" || fail "首次编译失败，见 $OUT 对应构建日志"
python3 "$SCRIPTS/stage8-kalloc-backfill.py" || fail "kalloc 回填失败"
bash "$SCRIPTS/build-star-native.sh" || fail "回填后重编失败"
python3 "$SCRIPTS/stage8-kalloc-backfill.py" --check || fail "stage-8 kalloc 闸门未通过，禁止打包"

echo "=== [4/6] 符号/反汇编闸门（llvm-nm，不用 strings/GNU nm）==="
U="$TREE/BUILD/obj/RELEASE_ARM64_BCM2837/mach.release.bcm2837.unstripped.noctf"
K="$TREE/BUILD/obj/RELEASE_ARM64_BCM2837/mach.release.bcm2837"
/usr/bin/llvm-nm "$U" 2>/dev/null | grep -q '_vm_shared_region_slide_part_v5' \
  || fail "内核缺 _vm_shared_region_slide_part_v5 符号"
CALLS="$(llvm-objdump -d --disassemble-symbols=_shared_region_pager_data_request "$K" 2>/dev/null \
  | grep -c '<_vm_shared_region_slide_part_v5>')"
[ "$CALLS" -ge 2 ] || fail "data_request->slide_part_v5 调用数=$CALLS，期望>=2"
echo "  符号存在；调用数=$CALLS"

echo "=== [5/6] 打包（单变量：仅内核变化）==="
bash "$SCRIPTS/_s222_pack.sh" || fail "打包失败"

echo "=== [6/6] 结果 ==="
[ -f "$OUT" ] || fail "未生成 $OUT"
ls -l "$OUT"
md5sum "$OUT"
python3 "$SCRIPTS/xnup_info.py" "$OUT" 2>/dev/null | grep -E 'cmdline|kernel|ramdisk|payload' | head -8
echo "BUILD_OK: $OUT"
echo "下一步：真机 fastboot boot 并按 AI_BUILD.md 第 6 节判据确认；见第 7 节禁忌。"
