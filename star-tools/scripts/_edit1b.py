#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""s218 edit 1b: fix residual speeds[i].level reference in step_core_power."""
F = "/root/star26/star-native/bsd/dev/star/annibale_adreno.c"
src = open(F, "r").read()
old = 'printf("adreno: %u: RPMh has no level %u for the 3D core\'s rail\\n", step, speeds[i].level);'
new = 'printf("adreno: %u: RPMh has no level %u for the 3D core\'s rail\\n", step, star_gpu_speeds[i].level);'
assert src.count(old) == 1, "residual not unique: %d" % src.count(old)
src = src.replace(old, new, 1)
open(F, "w").write(src)
print("edit 1b done")
