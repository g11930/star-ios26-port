#!/usr/bin/env python3
"""Assemble the star-native tree from the official xnu-12377.121.6 baseline.

Rules (user decision 2026-11-14): the K90 release tree is reference only.  The new
tree carries the Linux/WSL build fixups and platform-independent runtime patches,
plus the already-proven standard-UFSHCI storage stack, but NO K90 platform driver
(annibale_*, adreno8_*, Mini*, Annibale*).  Their entry points are provided by
star_platform_stubs.c until each subsystem is rewritten for SM8350 / star.

Idempotent: --reset restores the destination worktree to the clean baseline.
"""
import argparse
import os
import shutil
import subprocess

SRC = "/root/star26/kbuild/xnu-12377.121.6"
DST = "/root/star26/star-native"

# Untracked files/directories that are build infrastructure, not K90 drivers.
INFRA = [
    "bsd/miscfs/apfs",
    "bsd/miscfs/ramfs",
    "bsd/pthread/pthread_kext_static.c",
    "bsd/kern/kern_minimac.c",
    "bsd/kern/kern_minisandbox_container.inc",
    "libkern/amfi/miniamfi.c",
    "libkern/amfi/miniamfi_entitlements.cpp",
    "osfmk/minicrypto",
    "osfmk/arm64/generic_arm64_support.c",
    "osfmk/arm64/loader_return.c",
    "osfmk/arm64/user_exception_trace.c",
    "osfmk/arm64/gic_v3_irq.c",
    "osfmk/arm64/psci_smp.c",
    "osfmk/arm64/psci_smp.h",
    "osfmk/arm64/ppl",
    "osfmk/arm64/tunables",
    "iokit/Kernel/GenericARMPE.cpp",
    "config/MASTER.arm64.bcm2837",
    "pexpert/pexpert/arm64/BCM2837.h",
    # headers the storage stack and bsd_init.c include; declarations only, no drivers
    "bsd/sys/annibale_input.h",
    "bsd/sys/annibale_audio.h",
    "bsd/sys/annibale_virtio_blk.h",
    "bsd/sys/annibale_sparse.h",
    "bsd/sys/annibale_apfs_check.h",
]

# Standard UFSHCI storage stack: no SM8750 physical addresses, proven on star
# (P38: 32375 reads / 0 errors, three APFS containers mounted).
UFS_FILES = [
    "annibale_ufs.c",
    "annibale_ufshc.c",
    "annibale_ufshc.h",
    "annibale_ufs_rw.inc",
    "annibale_ufshc_rw.inc",
    "annibale_disk_nodes.inc",
]

STUBS = r'''/*
 * star-native platform stubs (stage 0).
 *
 * The K90 release tree's platform drivers are NOT part of this tree.  These
 * entry points still exist because generic kernel files (bsd_init.c,
 * machine_routines.c, loader_return.c) call them; every one is a no-op until
 * the corresponding subsystem is written against star-B.dtb (SM8350).
 * Nothing here touches a device register.
 */
#include <sys/param.h>
#include <sys/systm.h>
#include <sys/types.h>
#include <sys/sysctl.h>
#include <mach/mach_types.h>
#include <stdbool.h>

/* The UFSHCI stack registers its counters under kern.annibale; keep the node
 * until the storage layer is renamed for star in stage 1. */
SYSCTL_NODE(_kern, OID_AUTO, annibale, CTLFLAG_RW | CTLFLAG_LOCKED, 0,
    "star stage-0 storage counters");

/* star is NOT annibale: returning false keeps the stack away from the K90
 * SPMI/PMIC register writes in annibale_ufs_rw.inc. */
bool annibale_platform_is_annibale(void) { return false; }
void annibale_spmi_lock(void) {}
void annibale_spmi_unlock(void) {}
bool annibale_virtio_blk_dev(dev_t dev) { (void)dev; return false; }
void AnnibaleDiskStart(uint64_t size_bytes) { (void)size_bytes; }

void annibale_input_init(void) {}
void annibale_audio_init(void) {}
void annibale_virtio_blk_init(void) {}
void annibale_sparse_init(void) {}
bool annibale_gpu_stub_start(void) { return true; }
void annibale_apfs_check_init(void) {}

void adreno8_quiesce(void) {}
void adreno8_return_quiesce(void) {}
void annibale_wifi_stop(void) {}
void annibale_wifi_quiesce(void) {}
void annibale_haptic_quiesce(void) {}
void annibale_torch_quiesce(void) {}
bool annibale_iris_return_quiesce(void) { return true; }
void star_display_quiesce(void) {}
void star_display_poweroff(void) {}
void star_iosurface_usage(uint32_t *count, uint64_t *bytes)
{
	if (count) { *count = 0; }
	if (bytes) { *bytes = 0; }
}
'''


def git(cwd, *args):
    return subprocess.run(["git"] + list(args), cwd=cwd,
                          capture_output=True, text=True).stdout


def copy_rel(rel, dst_rel=None):
    s = os.path.join(SRC, rel)
    d = os.path.join(DST, dst_rel or rel)
    if not os.path.exists(s):
        print("  MISSING %s" % rel)
        return False
    os.makedirs(os.path.dirname(d), exist_ok=True)
    if os.path.isdir(s):
        if os.path.exists(d):
            shutil.rmtree(d)
        shutil.copytree(s, d)
    else:
        shutil.copy2(s, d)
    return True


def read(rel):
    with open(os.path.join(DST, rel), errors="replace") as fh:
        return fh.read()


def write(rel, text):
    with open(os.path.join(DST, rel), "w") as fh:
        fh.write(text)


def edit(rel, old, new, required=True):
    text = read(rel)
    n = text.count(old)
    if n != 1:
        if required:
            raise SystemExit("EDIT FAILED %s: expected 1 occurrence, got %d of %r" % (rel, n, old[:60]))
        return 0
    write(rel, text.replace(old, new))
    return 1


def filter_conf(rel, drop_prefixes, insert_after=None):
    lines = read(rel).splitlines(True)
    kept, dropped, inserted = [], 0, False
    for line in lines:
        if any(p in line for p in drop_prefixes):
            dropped += 1
            if insert_after and not inserted:
                kept.extend(insert_after)
                inserted = True
            continue
        kept.append(line)
    if insert_after and not inserted:
        kept.extend(insert_after)
    write(rel, "".join(kept))
    print("  %-28s dropped %d lines, inserted %d" % (rel, dropped, len(insert_after or [])))


KALLOC_REPL = [
    ("0x1d0a08", "0x1ab358"),   # __kalloc_type delta
    ("0x1c8c18", "0x1a3c48"),   # __kalloc_var  delta
    ("0x13e80",  "0x13680"),    # __kalloc_type size
    ("0x7df0",   "0x7710"),     # __kalloc_var  size
]
KALLOC_OLD_COMMENT = " * before __TEXT, so their offsets are stable across .text edits. */"
KALLOC_NEW_COMMENT = (
    " * before __TEXT.  These offsets are measured on the star-native kernel\n"
    "\t\t\t * by scripts/parse-kalloc-sections.py; recompute them after any change\n"
    "\t\t\t * that alters the section layout, or kalloc_type_view_copy() will write\n"
    "\t\t\t * into __TEXT and panic at boot (s1, 2026-11-15). */")


def fixup_kalloc_deltas():
    """The copied WSL/cctools fixup hardcodes kalloc section offsets measured
    on the K90 kernel.  star-native removed most platform drivers, so those
    offsets point into read-only __TEXT and the kernel panics before bsd_init
    (s1, 2026-11-15: ESR 0x9600004f at _kalloc_type_view_copy+0xd4).
    Measured with scripts/parse-kalloc-sections.py on the star-native binary.
    """
    rel = "osfmk/kern/kalloc.c"
    text = read(rel)
    for old, new in KALLOC_REPL:
        n = text.count(old)
        if n == 0 and text.count(new) == 2:
            continue                        # already applied
        if n != 2:
            raise SystemExit("FAILED %s: %s occurs %d times (want 2)" % (rel, old, n))
        text = text.replace(old, new)
    n = text.count(KALLOC_OLD_COMMENT)
    if n == 2:
        text = text.replace(KALLOC_OLD_COMMENT, KALLOC_NEW_COMMENT)
    write(rel, text)
    if not all(text.count(o) == 0 and text.count(nw) == 2 for o, nw in KALLOC_REPL):
        raise SystemExit("FAILED: kalloc delta fixup did not stick")
    print("  kalloc.c: star-native measured offsets applied")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--reset", action="store_true")
    args = ap.parse_args()

    if args.reset:
        git(DST, "checkout", "--", ".")
        git(DST, "clean", "-fd")
        print("reset star-native to clean baseline")

    print("=== 1. modified official files (build fixups + platform-independent patches) ===")
    mods = [ln[3:] for ln in git(SRC, "status", "--porcelain").splitlines()
            if ln.startswith(" M")]
    for rel in mods:
        copy_rel(rel)
    print("  copied %d modified official files" % len(mods))

    print("=== 1b. star-native kalloc section offsets (s1 panic fix) ===")
    fixup_kalloc_deltas()

    print("=== 2. untracked build infrastructure ===")
    ok = sum(copy_rel(r) for r in INFRA)
    print("  copied %d/%d infrastructure entries" % (ok, len(INFRA)))

    print("=== 3. standard UFSHCI storage stack -> bsd/dev/star/ ===")
    for f in UFS_FILES:
        copy_rel("bsd/dev/annibale/" + f, "bsd/dev/star/" + f)

    print("=== 4. conf cleanup: remove every K90 driver build entry ===")
    star_entries = [
        "bsd/dev/star/annibale_ufs.c\t\tstandard\n",
        "bsd/dev/star/annibale_ufshc.c\t\tstandard\n",
        "bsd/dev/star/star_platform_stubs.c\tstandard\n",
    ]
    filter_conf("bsd/conf/files",
                ["bsd/dev/annibale/", "bsd/dev/adreno8/", "bsd/dev/mhi/"],
                star_entries)
    filter_conf("iokit/conf/files", ["iokit/Kernel/Mini", "iokit/Kernel/Annibale"])
    filter_conf("osfmk/conf/files", ["osfmk/kern/annibale_threads.c"])
    edit("makedefs/MakeInc.def",
         "# Darwin-on-annibale: objects made outside this tree, linked when the build is given any (the\n"
         "# Wi-Fi driver, see bsd/dev/annibale_lx.c)\n"
         "LD_KERNEL_ARCHIVES += $(ANNIBALE_OBJECTS)\n", "")

    print("=== 5. ISA identity: star / SM8350, PAC emulation instead of K90 key-disable ===")
    edit("pexpert/pexpert/arm64/BCM2837.h",
         " * iOS 26 has only arm64e programs. The kernel stays arm64 and leaves the pointer\n"
         " * authentication keys disabled (SCTLR_EL1.EnIA/EnIB/EnDA/EnDB clear), so that the PAC and\n"
         " * AUT instructions of those programs leave pointers as they are, and the shared cache's\n"
         " * authenticated pointers are rebased as plain ones (vm_shared_region_slide_page_v3/v5).\n"
         " * The CPU subtype is reported as arm64e only so that ml_grade_binary() accepts them (boot-arg\n"
         " * arm64e=0: arm64, for iOS 16.5, whose dyld then picks its arm64 slice and shared cache).\n"
         " */\n"
         "#define ANNIBALE_ARM64E_USERLAND   1\n",
         " * star / SM8350 is ARMv8.2 and does NOT implement FEAT_PAuth: every PAC/AUT\n"
         " * instruction in the arm64e-only iOS 26 userland raises an uncategorized\n"
         " * synchronous exception.  sleh.c:handle_uncategorized() emulates the whole\n"
         " * PAuth family in software; the CPU subtype is still reported as arm64e so\n"
         " * ml_grade_binary() accepts the arm64e slices.  There is no arm64e=0 fallback.\n"
         " */\n"
         "#define STAR_ARM64E_USERLAND       1\n")
    edit("osfmk/arm/cpuid.c",
         "#elif defined(ANNIBALE_ARM64E_USERLAND)\n"
         "\t/* (see pexpert/arm64/BCM2837.h) boot-arg arm64e=0: arm64, for a system without arm64e programs */\n"
         "\tuint32_t arm64e = 1;\n\n"
         "\tPE_parse_boot_argn(\"arm64e\", &arm64e, sizeof(arm64e));\n"
         "\tcpuid_cpu_info.arm_info.arm_arch = arm64e ? CPU_ARCH_ARMv8E : CPU_ARCH_ARMv8;\n",
         "#elif defined(STAR_ARM64E_USERLAND)\n"
         "\t/* star: arm64e-only userland, PAuth emulated in software (sleh.c) */\n"
         "\tcpuid_cpu_info.arm_info.arm_arch = CPU_ARCH_ARMv8E;\n")
    edit("osfmk/arm64/sleh.c",
         " * iOS 26 ships arm64e-only userland.  On K90's SM8750 the kernel leaves all\n",
         " * iOS 26 ships arm64e-only userland.  On a CPU with FEAT_PAuth the kernel leaves all\n",
         required=False)

    # Comment-only cosmetic cleanup so the new tree does not read like the K90 port.
    for rel in mods:
        t = read(rel)
        n = t.replace("annibale:", "star:").replace("(annibale)", "(star)")
        if n != t:
            write(rel, n)

    print("=== 5b. GenericARMPE: keep the generic platform expert, drop K90 Mini* starts ===")
    edit("iokit/Kernel/GenericARMPE.cpp",
         "#include \"MiniDrivers.h\"\n",
         "/* star stage 0: the K90 Mini* drivers are not in this tree.  The star\n"
         " * display/IOSurface services are wired back in here in stage 1. */\n")
    edit("iokit/Kernel/GenericARMPE.cpp",
         "\t/* Stand-ins for the closed graphics drivers that the iOS window server talks to. */\n"
         "\tMiniIOSurfaceStart(this);\n"
         "\tMiniIOMobileFramebufferStart(this);\n"
         "\tMiniAppleARMBacklightStart(this);\n"
         "\tMiniAppleKeyStoreStart();\n"
         "\tMiniIONetworkStackStart();\n",
         "\t/* star stage 0: no display/IOSurface services yet.  These are the\n"
         "\t * first subsystem to be written against star-B.dtb (SM8350). */\n")

    print("=== 5c. name the display/IOSurface entry points for star, not K90 ===")
    renames = {
        "MiniIOMobileFramebufferQuiesce": "star_display_quiesce",
        "MiniIOMobileFramebufferPowerOff": "star_display_poweroff",
        "MiniIOSurfaceUsage": "star_iosurface_usage",
    }
    for rel in ("osfmk/arm64/machine_routines.c", "osfmk/arm64/loader_return.c"):
        t = read(rel)
        for old, new in renames.items():
            t = t.replace(old, new)
        write(rel, t)

    print("=== 6. platform stubs ===")
    write("bsd/dev/star/star_platform_stubs.c", STUBS)

    print("=== 7. verification ===")
    leftovers = []
    for root, dirs, files in os.walk(DST):
        if "/.git" in root or "/BUILD" in root:
            continue
        for f in files:
            p = os.path.join(root, f)
            r = os.path.relpath(p, DST)
            if r.startswith(("bsd/dev/annibale/", "bsd/dev/adreno8/", "bsd/dev/mhi/",
                             "iokit/Kernel/Mini", "iokit/Kernel/Annibale")):
                leftovers.append(r)
    print("  K90 driver files left in tree: %d" % len(leftovers))
    for r in leftovers[:10]:
        print("   ", r)
    print("  status files: %d" % len(git(DST, "status", "--porcelain").splitlines()))
    print("DONE")


if __name__ == "__main__":
    main()
