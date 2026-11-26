p = "/root/star26/star-native/iokit/Kernel/StarDisplayCompat.cpp"
s = open(p).read()
n = s.count('extern "C" ')
s = s.replace('extern "C" ', 'extern "C" __attribute__((weak)) ')
open(p, "w").write(s)
print("weakened", n, "definitions")
