# AI 一键构建「可开机」镜像指南

这份文档给 AI（或任何人）看：拿到本仓库后，如何在已配置好的环境里，
按一条确定性的流水线构建出可在小米 11 Ultra（代号 star / SM8350）上开机的
iOS 26 引导镜像（`s222-boot.img`）。

一句话指令（可直接喂给 AI）：

> 在已配好工具链、SDK 与设备基线部件的本机 WSL 环境里，按本仓库
> `AI_BUILD.md` 的流程执行 `bash star-tools/ai-build.sh`，以 stage-8 kalloc
> 闸门、`llvm-nm` 符号检查和 cmdline 校验作为通过判据，产出
> `s222-boot.img`。

---

## 0. 先说清楚边界（AI 必须先读）

本仓库**只包含源码与脚本**，能从头重建的部分是「内核」。但有两类东西
不在仓库里，缺了任意一类都开不了机，AI 不得假装可以纯 clone 构建：

| 类别 | 内容 | 来源 | 仓库是否包含 |
|---|---|---|---|
| 构建环境 | WSL `Ubuntu-24.04`、交叉工具链、iOS 26 XNU SDK | 事先配置好的本机 | 否 |
| 设备基线部件 | `loader.efi`、`ramdisk`、`rdimage`、`memsize`、`identity`，以及 reseal 基底 `p2-boot.img` | 从目标机既有镜像/设备提取 | 否 |
| 内核源码 + 移植补丁 | XNU 12377.121.6 + star 移植 | 本仓库 | **是** |

因此「一键」的准确含义是：**在上述环境与部件已就位的前提下**，一条命令
串起「建树 → 打补丁 → 编译 → 闸门 → 打包」，而不是「空环境 clone 即开机」。

当前已知能进桌面的镜像是 `s217`（未打 pager 补丁）。`s222` 是在 `s217`
基础上仅替换内核、加入 4K shared-region-slide 修复的**候选版本**，用于验证
「arm64e 用户态在 4K 内核页下滑移 dyld shared cache」的越界修复，**尚未真机
刷写验证**。构建产物必须真机 `fastboot boot` 后按第 6 节判据确认，才算「能开机」。

---

## 1. 前置条件清单（AI 开工前逐项核对）

环境（WSL `Ubuntu-24.04`）：

- 交叉编译器 `/root/xnu26-test/bin/xnu26-clang`、`xnu26-clang++`
- `iig` = `/root/xnu26-test/bin/iig`、`migcc` = `/root/xnu26-test/bin/xnu26-migcc`
- `xcrun` = `/root/star-build/xnu-deps/host/bin/xcrun`
- SDK `iPhoneOS16.5.xnu.sdk` + `Platforms/iPhoneOS.platform`
- `llvm-nm` / `llvm-objdump`（用 `/usr/bin/llvm-nm`，**不要**用 GNU `nm`）
- `flex` / `bison` / `m4` / `python3`

设备基线部件（放到 `/root/star26/baseline/s221parts/`）：

- `loader.efi`、`ramdisk`、`rdimage`、`memsize`、`identity`
- cmdline 公式基线：`/root/star26/baseline/s207parts/cmdline`
- reseal 基底：`/root/star26/p2/p2-boot.img`

目标设备：小米 11 Ultra，darwin 分区已写入 iOS 26 三容器；能进 Android
fastboot。

任一缺失：停止，向环境所有者索取，**不要用占位符或猜测值代替**。

---

## 2. 一键构建

```bash
bash star-tools/ai-build.sh
```

脚本会依次完成第 3、4、5 节并把日志留在 `/mnt/c/ios26/star-native-build.log`。

需要改路径时，用环境变量覆盖，不改动脚本：

```bash
TREE=/root/star26/star-native \
BASELINE=/root/star26/baseline \
OUT=/mnt/c/ios26/s222-boot.img \
bash star-tools/ai-build.sh
```

---

## 3. 建树与移植补丁（确定性顺序，不可换）

工作树固定为 `/root/star26/star-native`，基线为官方 `xnu-12377.121.6`
（`apple-oss-distributions/xnu` tag，commit 前缀 `ac9718f`）。K90 / Annibale
树只作结构参考，**不照搬平台驱动**。

按顺序执行（脚本已串联）：

```bash
python3 star-tools/scripts/build-star-native-tree.py --reset
python3 star-tools/scripts/stage1-storage.py
python3 star-tools/scripts/stage2-display-probe.py
python3 star-tools/scripts/stage7-display-abi.py
python3 star-tools/scripts/stage7b-display-compat.py
cd "$TREE" && git apply ../star-ios26-port/star-tools/ai-build/native-4k-shared-region-slide.patch
python3 ../star-ios26-port/star-tools/ai-build/_s222_plainauth_fix.py
```

每步作用：

- `build-star-native-tree.py --reset`：从 pristine 基线重建，幂等；叠加
  WSL 编译修复与平台无关的运行时补丁，带已验证的 UFSHCI 存储栈；**不含**
  K90 平台驱动（由 `star_platform_stubs.c` 提供入口桩）。
- `stage1-storage.py`：发布 `disk0` / APFS 容器 / System·Data·Preboot 卷，
  容量取自 loader 的 UFS 探测页；RTC 改用 star 时钟源。
- `stage2-display-probe.py`：只读显示流水线探针（默认关，boot-arg
  `star_display_probe=1` 才启用），**不写 DPU 寄存器**。
- `stage7-display-abi.py` + `stage7b-display-compat.py`：搬入 iOS 用户态必需的
  IOSurface / IOMobileFramebuffer / GPU ABI，硬件侧保持 stub；`fb_flip/fb_dim/fb_dcs`
  默认 0，帧直写单缓冲 framebuffer `0xEA600000`。
- `native-4k-shared-region-slide.patch`（420 行，改 3 个 vm 文件）：核心修复。
  官方 pager 按 16KiB slide page 设计，内核 `PAGE_SIZE` 是 4KiB，越界 `bcopy`
  会 panic；补丁新增 peek / slide-part 逻辑与 `vm_shared_region_slide_part_v5`。
- `_s222_plainauth_fix.py`：arm64 内核无硬件 PAC，arm64e cache 的 authenticated
  rebase 必须把 plain pointer 写回；该脚本给新函数的 `#else` 分支补上
  `memcpy(rebaseLocation, &value, sizeof(value))`，并要求**精确匹配 1 处**，
  否则中止。

---

## 4. 编译 + stage-8 kalloc 闸门

```bash
bash star-tools/scripts/build-star-native.sh        # build #1
python3 star-tools/scripts/stage8-kalloc-backfill.py  # 回填段常量到 kalloc.c
bash star-tools/scripts/build-star-native.sh        # build #2
python3 star-tools/scripts/stage8-kalloc-backfill.py --check  # 闸门，必须 PASS
```

为什么必须先回填再重编：`__kalloc_type` / `__kalloc_var` 在 `__DATA_CONST`，
偏移随代码量变化。新增 pager 代码移动了段，若用旧常量，`_kalloc_type_view_copy`
会写只读段并 panic（ESR `0x96000006`）。从内存实测写回，再重编，最后 `--check`
比对。

**诊断日志铁律**：内核开启 `CONFIG_NO_PRINTF_STRINGS`，`printf()` 是空宏且格式串
被剥离。新增诊断一律用 `IOLog()`，否则刷机后什么都看不到。

**验证补丁是否编进内核**：用 `llvm-nm`，不要用 `strings` 或 GNU `nm`
（格式串会被合并/剥离，GNU 工具不认 Mach-O）：

```bash
/usr/bin/llvm-nm "$TREE/BUILD/obj/RELEASE_ARM64_BCM2837/mach.release.bcm2837.unstripped.noctf" \
  | grep _vm_shared_region_slide_part_v5        # 必须命中
llvm-objdump -d --disassemble-symbols=_shared_region_pager_data_request \
  "$TREE/BUILD/obj/RELEASE_ARM64_BCM2837/mach.release.bcm2837" \
  | grep -c '<_vm_shared_region_slide_part_v5>' # 必须 >= 2
```

---

## 5. 打包成可刷镜像（单变量原则）

打包脚本 `star-tools/scripts/_s222_pack.sh` 遵循「单变量」：`s222` 相对 `s217`
**只有内核变化**，其余部件与 cmdline 逐字节复用，便于定位问题。

```bash
bash star-tools/scripts/_s222_pack.sh
```

流程要点（脚本已实现并自带校验）：

1. 从 `s221parts` 复制 `loader.efi / ramdisk / rdimage / memsize / identity`，
   只把新编译的 `mach.release.bcm2837` 作为 `kernel`。
2. 符号/反汇编闸门（同第 4 节）不过则中止。
3. cmdline 从 `s221-boot.img` 逐字节提取，并与公式
   `s207parts/cmdline + " gpu_irq=0 pac_patch=2 pac_patch_delay=900 pac_patch_budget=256 pac_patch_burst=8"`
   交叉比对；正文长度 ≤ 1024（loader 上限）；**出现 `fb_diff=1` 立即中止**。
4. `mkpayload.py` 合成载荷（上限 `PAYLOAD_CAP=0x03700000`，55MiB），
   `reseal-loader-img.py`  reseal 成 `s222-boot.img`。
5. 用 `xnup_info.py` 回读镜像核对条目 md5。

---

## 6. 刷机与「能开机」判据

```bash
adb reboot bootloader           # 回 Android fastboot
fastboot boot s222-boot.img     # 约 60-70 秒
```

判据（全部满足才算构建成功）：

- 进入桌面，表现与 `s217` 相当；
- 无 pager 越界 panic、无 unslid 指针 fault；内核 alive 后先 `oem log`，
  已 returned 则直接 `get_staged`（用 Windows 路径 `C:/ios26/...`）；
- FIPS PASSED；
- 日志格式串特征为现线（如 `StarDisk: published`），不是旧线残留。

失败回滚点：`s221`（仅内核不同）、`s217`（未打 pager 补丁、已知可进桌面）。

---

## 7. 禁忌清单（违反任一条 = 开不了机或看不到日志）

1. cmdline **绝不**加 `fb_diff=1`：双重代价（逐像素读 ~600ms/帧 + 强制单线程
   绕过 dirtyBand），实测单帧 686ms vs 17ms。
2. 新诊断代码**必须** `IOLog()`，不能 `printf()`（空宏）。
3. **必须** arm64 内核 + arm64e 用户态。SM8350 无 `FEAT_PAuth`，靠内核软件
   模拟 PAC（`sleh.c`）；不能退回 arm64 用户态。
4. 改内核代码后**必须**重跑 stage-8 kalloc 回填，不满足闸门不许打包。
5. 验证符号**必须**用 `llvm-nm`，不能用 `strings` / GNU `nm`。
6. 调试 cmdline 显式 `fb_dcs=0 fb_dim=0 fb_flip=0`（`fb_dcs` 默认 4 会按
   DPU 12.0 偏移写 star 的 DPU）。
7. 不要照搬 K90 的 `0xfc800000` 双缓冲；star 是单缓冲 `0xEA600000`。

---

## 8. 相关文件

- `star-tools/ai-build.sh` —— 一键入口
- `star-tools/ai-build/` —— 补齐的补丁与打包工具
- `star-tools/scripts/` —— 完整构建/诊断脚本（2149 个）
- 基线：`apple-oss-distributions/xnu` @ `xnu-12377.121.6` (`ac9718f`)
