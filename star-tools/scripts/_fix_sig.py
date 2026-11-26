import re

P = "/root/star26/star-native/bsd/dev/star/annibale_adreno.c"
s = open(P).read()

old_map = """void
annibale_gpu_mapped(void)
{
	space_commit(&core_space);
}"""
new_map = """bool
annibale_gpu_mapped(void)
{
	return space_commit(&core_space) == 0;
}"""

if old_map in s:
    s = s.replace(old_map, new_map)
    print("mapped(): signature fixed")
else:
    print("mapped(): pattern not found")

i = s.find("annibale_gpu_unmap(uint64_t address, uint64_t size)\n{")
if i >= 0:
    start = s.rfind("void\n", 0, i)
    head_end = s.find("{", i) + 1
    # find the matching closing brace of this function
    depth = 1
    j = head_end
    while depth:
        if s[j] == "{":
            depth += 1
        elif s[j] == "}":
            depth -= 1
        j += 1
    body = s[head_end:j - 1]
    body = body.rstrip()
    new = ("bool\nannibale_gpu_unmap(uint64_t address, uint64_t size)\n{" + body +
           "\n\treturn true;\n}")
    s = s[:start] + new + s[j:]
    print("unmap(): signature fixed")
else:
    print("unmap(): not found")

open(P, "w").write(s)
