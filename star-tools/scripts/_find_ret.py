import re
p = "/root/star26/star-native/iokit/Kernel/AnnibaleGPU.cpp"
lines = open(p).read().split("\n")

start = None
for i, l in enumerate(lines):
    if "AnnibaleGPUUserClient::externalMethod(uint32_t selector" in l:
        start = i
        break
for j in range(start, min(start + 400, len(lines))):
    if re.match(r"\treturn ret;", lines[j]):
        lo = max(j - 14, 0)
        hi = min(j + 3, len(lines))
        for k in range(lo, hi):
            print("%d: %s" % (k + 1, lines[k]))
        break
