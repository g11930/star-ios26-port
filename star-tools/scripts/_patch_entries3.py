p = "/root/star26/star-native/iokit/Kernel/AnnibaleGPU.cpp"
s = open(p).read()

old = """		if (selector >= 0x40 && selector <= 0x4c && said++ < 80) {"""
new = """		if (selector >= 0x44 && selector <= 0x4c && said++ < 60) {"""

assert old in s
s = s.replace(old, new, 1)
open(p, "w").write(s)
print("entry log narrowed to submits only")
