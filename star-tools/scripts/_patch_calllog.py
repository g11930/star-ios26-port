import re

p = "/root/star26/star-native/iokit/Kernel/AnnibaleGPU.cpp"
s = open(p).read()

anchor = "AnnibaleGPUUserClient::externalMethod(uint32_t selector, IOExternalMethodArguments * args,"
i = s.find(anchor)
assert i > 0
brace = s.find("{", i)
# insert right after the opening brace
ins = """
	{
		/* every request in order, and from whom: freedreno's way to a screen is this list */
		static unsigned said;

		if (said++ < 48) {
			char who[32] = "?";

			proc_selfname(who, sizeof(who));
			IOLog("AnnibaleGPU: call %#x size %zu from %s\\n", selector,
			    args != NULL ? args->scalarInputCount : 0, who);
		}
	}
"""
s = s[:brace + 1] + ins + s[brace + 1:]
open(p, "w").write(s)
print("selector logging added")
