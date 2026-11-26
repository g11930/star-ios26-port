import re, shutil

SRC = "/root/g11930-ref/xnu/files/bsd/dev/redwood_image.c"
DST = "/root/star26/star-native/bsd/dev/star/annibale_image.c"

s = open(SRC).read()
s = re.sub(r"\bredwood_", "annibale_", s)
open(DST, "w").write(s)

CONF = "/root/star26/star-native/bsd/conf/files"
lines = open(CONF).read().splitlines()
if not any("annibale_image.c" in l for l in lines):
    for i, l in enumerate(lines):
        if "annibale_adreno.c" in l:
            lines.insert(i + 1, "bsd/dev/star/annibale_image.c\t\tstandard")
            break
    open(CONF, "w").write("\n".join(lines) + "\n")
    print("conf/files: annibale_image.c added")
else:
    print("conf/files: already there")

print("lines:", len(s.splitlines()))
