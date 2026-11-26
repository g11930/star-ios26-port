p = "/root/star26/star-native/iokit/Kernel/AnnibaleGPUSubmit.inc"
s = open(p).read()

old = """out:
	if (bos != NULL) {"""
new = """out:
	{
		/* why a submission was not taken, in the words of the request that made it */
		static unsigned said;

		if (ret != kIOReturnSuccess && said++ < 12) {
			IOLog("AnnibaleGPU: submit refused %#x: %u cmds in %u bos, flags %#x, fence %u, %u words\\n",
			    ret, request->nr_cmds, request->nr_bos, request->flags, request->fence, count);
		}
	}
	if (bos != NULL) {"""

assert old in s
s = s.replace(old, new, 1)
open(p, "w").write(s)
print("submit failure logging added")
