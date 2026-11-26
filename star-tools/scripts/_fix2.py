p = "/root/star26/star-native/bsd/dev/star/annibale_adreno.c"
s = open(p).read()
s = s.replace("return space_commit(&core_space) == 0;",
              "space_commit(&core_space);\n\treturn true;")
open(p, "w").write(s)
print("ok")
