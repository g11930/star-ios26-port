p = "/root/star26/star-native/iokit/Kernel/AnnibaleGPU.cpp"
s = open(p).read()
old = "bool available = gGPUStub || (!gGPUReported && annibale_gpu_ready());"
new = ("/* One GPU, one service: once it is reported ready every open is answered, not only the first. */\n"
       "\tbool available = gGPUStub || gGPUReported || annibale_gpu_ready();")
assert old in s
open(p, "w").write(s.replace(old, new, 1))
print("open gate widened")
