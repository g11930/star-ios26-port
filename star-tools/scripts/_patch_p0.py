p = "/root/star26/hackios-xnu-userland/userland/src/inject/sb_metal_experiment.m"
s = open(p).read()
old = 'strcmp(name, "Adreno (TM) 830")'
assert s.count(old) == 2
s = s.replace(old, 'strncmp(name, "Adreno", 6)')
open(p, "w").write(s)
print("backend name check widened to any Adreno")

q = "/root/star26/star-native/bsd/dev/star/annibale_adreno.c"
t = open(q).read()
old2 = "#define GPU_CHIP_ID             0x06030500ull   /* dt: qcom,chipid */"
new2 = ("#define GPU_CHIP_ID             0x06000600ull   /* a660: family 6, core 6 (the DT chipid 0x06030500\n"
        "                                                 * decodes as a 7c+ Gen 3, which is a different core) */")
assert old2 in t
t = t.replace(old2, new2, 1)
open(q, "w").write(t)
print("GPU_CHIP_ID set to a660's 0x06000600")
