#!/usr/bin/env python3
"""stage 10: checkpoints, so the kernel can be asked to stop before it wedges.

The stage-9 kernel gets past the kalloc validation that stopped every earlier build,
then inside the first second the loader's USB endpoint stops answering, the
heartbeat stops and the phone comes back to Android ~50 s later -- with nothing in
`logdump` past "jumping to".  No channel survives that, so the question "how far
did it get" has to be answered by the kernel itself.

The loader already has that tool (`checkpoint=<n>` boot-arg, loader_checkpoint(n)
in the kernel): the kernel jumps back to the loader at that point, the return is
orderly, the loader composes the logs and writes them to the logdump partition --
which is readable from Android afterwards, no race.

Nine points, in execution order:

  1 arm_vm_init           the first C code
  2 kalloc_init           in
  3 kalloc_init           out (the validation that used to panic)
  4 GenericARMPE::start   IOKit platform expert
  5   before MiniIOSurfaceStart / MiniIOMobileFramebufferStart  (stage-7 display)
  6   after  AnnibaleGPUStartStub  (stage-7b)
  7 bsd_init              in
  8   before annibale_ufs_init     (star's own UFS driver)
  9   after  star_display_handoff

Run with checkpoint=9 and work downwards.
"""
import sys

PATCHES = [
    ("/root/star26/star-native/osfmk/arm64/arm_vm_init.c", "c", [
        ("decl", "extern void loader_checkpoint(uint64_t);\n", None),
        ("cp1",
         "arm_vm_init(uint64_t memory_size, boot_args * args)\n{\n\tvm_map_address_t va_l1, va_l1_end;",
         "arm_vm_init(uint64_t memory_size, boot_args * args)\n{\n\tloader_checkpoint(1);\n\tvm_map_address_t va_l1, va_l1_end;"),
    ]),
    ("/root/star26/star-native/osfmk/kern/kalloc.c", "c", [
        ("decl", "extern void loader_checkpoint(uint64_t);\n", None),
        ("cp2",
         "kalloc_init(void)\n{\n\t/*\n\t * Allocate scratch space to parse kalloc_type_views",
         "kalloc_init(void)\n{\n\tloader_checkpoint(2);\n\t/*\n\t * Allocate scratch space to parse kalloc_type_views"),
        ("cp3",
         "\tkmem_free(kernel_map, (vm_offset_t) kt_buffer, kt_scratch_size);\n}\nstatic const char kalloc_p7_marker",
         "\tkmem_free(kernel_map, (vm_offset_t) kt_buffer, kt_scratch_size);\n\tloader_checkpoint(3);\n}\nstatic const char kalloc_p7_marker"),
    ]),
    ("/root/star26/star-native/iokit/Kernel/GenericARMPE.cpp", "cpp", [
        ("decl", "extern \"C\" void loader_checkpoint(uint64_t);\n", None),
        ("cp4",
         "\tIOLog(\"GenericARMPE: platform \\\"%s\\\"\\n\", provider->getName());",
         "\tIOLog(\"GenericARMPE: platform \\\"%s\\\"\\n\", provider->getName());\n\tloader_checkpoint(4);"),
        ("cp5",
         "\tMiniIOSurfaceStart(this);\n\tMiniIOMobileFramebufferStart(this);\n\tAnnibaleGPUStartStub();",
         "\tloader_checkpoint(5);\n\tMiniIOSurfaceStart(this);\n\tMiniIOMobileFramebufferStart(this);\n\tAnnibaleGPUStartStub();\n\tloader_checkpoint(6);"),
    ]),
    ("/root/star26/star-native/bsd/kern/bsd_init.c", "c", [
        ("decl", "extern void loader_checkpoint(uint64_t);\n", None),
        ("cp7",
         "bsd_init(void)\n{\n\tstruct uthread *ut;",
         "bsd_init(void)\n{\n\tloader_checkpoint(7);\n\tstruct uthread *ut;"),
        ("cp8",
         "\t\tannibale_ufs_init();\n\t\tstar_display_probe();",
         "\t\tloader_checkpoint(8);\n\t\tannibale_ufs_init();\n\t\tloader_checkpoint(9);\n\t\tstar_display_probe();"),
    ]),
]


def main():
    for path, kind, edits in PATCHES:
        src = open(path).read()
        if "loader_checkpoint(" in src:
            print("  already patched: %s" % path)
            continue
        for name, old, new in edits:
            if new is None:
                continue        # the declaration is inserted after the includes below
            n = src.count(old)
            if n != 1:
                print("FAILED %s in %s: %d matches" % (name, path, n))
                return 1
            src = src.replace(old, new, 1)
            print("  %s: %s" % (name, path.split("/")[-1]))
        decl = ('extern "C" void loader_checkpoint(uint64_t);' if kind == "cpp"
                else "extern void loader_checkpoint(uint64_t);")
        if "void loader_checkpoint(uint64_t)" not in src:
            # after the last #include line
            lines = src.split("\n")
            last = max(i for i, l in enumerate(lines) if l.startswith("#include"))
            lines.insert(last + 1, "\n/* star stage 10: the loader's bring-up checkpoint */\n" + decl)
            src = "\n".join(lines)
            print("  decl: %s" % path.split("/")[-1])
        open(path, "w").write(src)

    total = 0
    for path, _ in PATCHES:
        c = open(path).read().count("loader_checkpoint(")
        print("  %-28s %d call sites" % (path.split("/")[-1], c - 1))
        total += c - 1
    print("total checkpoints: %d" % total)
    return 0 if total >= 9 else 1


if __name__ == "__main__":
    sys.exit(main())
