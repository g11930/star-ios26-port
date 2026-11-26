p = "/root/star26/star-native/iokit/Kernel/AnnibaleGPU.cpp"
s = open(p).read()

old = """		if (said++ < 48) {
			char who[32] = "?";

			proc_selfname(who, sizeof(who));
			IOLog("AnnibaleGPU: call %#x size %zu from %s\\n", selector,
			    args != NULL ? args->structureInputSize : 0, who);
		}"""

new = """		if (selector >= 0x40 && selector <= 0x4c && said++ < 80) {
			char who[32] = "?";

			proc_selfname(who, sizeof(who));
			IOLog("AnnibaleGPU: call %#x size %zu from %s\\n", selector,
			    args != NULL ? args->structureInputSize : 0, who);
		}"""

assert old in s
s = s.replace(old, new, 1)
open(p, "w").write(s)
print("entry log narrowed to msm selectors")
