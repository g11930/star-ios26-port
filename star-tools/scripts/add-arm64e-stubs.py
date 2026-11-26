import io
P="/root/star26/star-native/osfmk/arm64/loader_return.c"
src=open(P,encoding="utf-8",errors="surrogateescape").read()
if "__firehose_buffer_create" in src:
    print("stubs already present"); raise SystemExit
STUBS = '''
/*
 * arm64e link fixups.
 *
 * Apple's kernel gets these from the firehose kext, which this tree does not
 * build.  With -arch arm64 the references land in the GOT as weak imports and
 * link fine; with -arch arm64e the compiler emits a direct branch, the address
 * is 0, and ld fails with "branch out of range ... to ___firehose_merge_updates
 * (0x00000000)".  Giving them real (never used) definitions in the kernel is
 * enough: firehose is only reachable from the LOGBUFFERMAP ioctl and
 * log_payload_send, neither of which this bring-up kernel calls.
 */
void *__firehose_buffer_create(size_t *size);
void *__firehose_buffer_create(size_t *size)
{
	if (size != NULL) {
		*size = 0;
	}
	return NULL;
}

int __firehose_kernel_configuration_valid(int chunks, int pages);
int __firehose_kernel_configuration_valid(int chunks, int pages)
{
	return chunks > 0 && pages > 0;
}

void __firehose_buffer_tracepoint_reserve(void);
void __firehose_buffer_tracepoint_reserve(void)
{
}

void __firehose_buffer_tracepoint_flush(void);
void __firehose_buffer_tracepoint_flush(void)
{
}

int __firehose_merge_updates(void);
int __firehose_merge_updates(void)
{
	return 0;
}

void pthread_start(void);
void pthread_start(void)
{
}
'''
open(P,"w",encoding="utf-8",errors="surrogateescape").write(src + STUBS)
print("appended firehose/pthread stubs to loader_return.c")
