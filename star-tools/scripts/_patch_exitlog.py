p = "/root/star26/star-native/iokit/Kernel/AnnibaleGPU.cpp"
s = open(p).read()

old = """	if (ret == kIOReturnSuccess && args->structureOutput != NULL) {
		if (args->structureOutputSize > size) {
			args->structureOutputSize = (uint32_t) size;
		}
		memcpy(args->structureOutput, &r, args->structureOutputSize);
	}
	return ret;"""

new = """	if (ret == kIOReturnSuccess && args->structureOutput != NULL) {
		if (args->structureOutputSize > size) {
			args->structureOutputSize = (uint32_t) size;
		}
		memcpy(args->structureOutput, &r, args->structureOutputSize);
	}
	if (selector >= 0x40 && selector <= 0x4c && ret != kIOReturnSuccess) {
		static unsigned said;

		if (said++ < 24) {
			char who[32] = "?";

			proc_selfname(who, sizeof(who));
			IOLog("AnnibaleGPU: %#x answered %#x to %s\\n", selector, ret, who);
		}
	}
	return ret;"""

assert old in s
s = s.replace(old, new, 1)
open(p, "w").write(s)
print("exit logging added")
