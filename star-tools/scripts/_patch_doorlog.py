p = "/root/star26/star-native/iokit/Kernel/AnnibaleGPU.cpp"
s = open(p).read()

old = """			IOLog("AnnibaleGPU: call %#x size %zu from %s\\n", selector,
			    args != NULL ? args->scalarInputCount : 0, who);"""
new = """			IOLog("AnnibaleGPU: call %#x size %zu from %s\\n", selector,
			    args != NULL ? args->structureInputSize : 0, who);"""
assert old in s
s = s.replace(old, new, 1)

old2 = """	if (args->structureInput == NULL || size > sizeof(r) || fBuffers == NULL) {
		return kIOReturnBadArgument;
	}"""
new2 = """	if (args->structureInput == NULL || size > sizeof(r) || fBuffers == NULL) {
		static unsigned said;

		if (said++ < 8) {
			IOLog("AnnibaleGPU: call %#x refused at the door: input %p, %zu bytes of %zu, buffers %p\\n",
			    selector, args->structureInput, size, sizeof(r), fBuffers);
		}
		return kIOReturnBadArgument;
	}"""
assert old2 in s
s = s.replace(old2, new2, 1)
open(p, "w").write(s)
print("door logging added")
