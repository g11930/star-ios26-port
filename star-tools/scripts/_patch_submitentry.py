p = "/root/star26/star-native/iokit/Kernel/AnnibaleGPU.cpp"
s = open(p).read()
old = """	case kMsmGemSubmit:
		ret = submit(&r.submit);
		break;"""
new = """	case kMsmGemSubmit:
	{
		static unsigned said;

		if (said++ < 10) {
			IOLog("AnnibaleGPU: submit in: %u cmds, %u bos, flags %#x, in_sync %u, out_sync %u\\n",
			    r.submit.nr_cmds, r.submit.nr_bos, r.submit.flags,
			    r.submit.nr_in_syncobjs, r.submit.nr_out_syncobjs);
		}
		ret = submit(&r.submit);
		break;
	}"""
assert old in s
s = s.replace(old, new, 1)
open(p, "w").write(s)
print("submit entry logging added")
