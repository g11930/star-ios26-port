import re

STUBS = "/root/star26/star-native/bsd/dev/star/star_platform_stubs.c"
s = open(STUBS).read()

if "annibale_adreno_init" not in s:
    # declare it and call it from the same boot hook that the reference port uses
    s = s.replace("void annibale_input_init(void) {}",
                  "extern void annibale_adreno_init(void);\n\n"
                  "/* The GPU is woken here, where the reference port wakes it too (its input init).\n"
                  " * It returns at once unless gpu=1 and the GPU's firmware is in the small image. */\n"
                  "void annibale_input_init(void)\n{\n\taannibale_adreno_init();\n}")
    s = s.replace("\taannibale_adreno_init();", "\tannibale_adreno_init();")
    open(STUBS, "w").write(s)
    print("stubs patched")
else:
    print("stubs already patched")

# firmware into the staging root, where mkapfs stores fw/ plainly
import shutil, os
src = "/root/star26/s111/fw-gpu"
dst = "/root/star26/s111/work/rootbuild/root/fw"
os.makedirs(dst, exist_ok=True)
for f in ("a660_gmu.bin", "a660_sqe.fw", "a660_zap.mdt", "a660_zap.b02"):
    shutil.copyfile(os.path.join(src, f), os.path.join(dst, f))
    print("fw:", f, os.path.getsize(os.path.join(dst, f)))
