#!/usr/bin/env python3
"""加 gpu_irq boot-arg 开关，定位 3 秒崩溃是否由 ISR 注册引起。"""
import sys

PATH = "/root/star26/star-native/bsd/dev/star/annibale_adreno.c"

with open(PATH, "r") as f:
    src = f.read()

OLD = """/* Attach the GPU's completion interrupt; a failure leaves the waiter sleeping its longest_us. */
static void
attach_gpu_completion_irq(void)
{
	if (gic_v3_spi_attach(0x12cu, false, gpu_completion_isr, NULL) == KERN_SUCCESS) {
		printf("adreno: the GPU's completion interrupt (SPI 0x12c) is attached\\n");
	} else {
		printf("adreno: the GPU's completion interrupt (SPI 0x12c) is not attached; "
		    "waits sleep instead of spinning\\n");
	}
}
"""

NEW = """/* Attach the GPU's completion interrupt; a failure leaves the waiter sleeping its longest_us.
 * gpu_irq=0 skips the attach entirely (sleep-only), for diagnosing whether the attach is safe. */
static void
attach_gpu_completion_irq(void)
{
	uint32_t gpu_irq = 1;

	PE_parse_boot_argn("gpu_irq", &gpu_irq, sizeof(gpu_irq));
	if (gpu_irq == 0) {
		printf("adreno: the GPU's completion interrupt is not attached (gpu_irq=0); "
		    "waits sleep instead of spinning\\n");
		return;
	}
	if (gic_v3_spi_attach(0x12cu, false, gpu_completion_isr, NULL) == KERN_SUCCESS) {
		printf("adreno: the GPU's completion interrupt (SPI 0x12c) is attached\\n");
	} else {
		printf("adreno: the GPU's completion interrupt (SPI 0x12c) is not attached; "
		    "waits sleep instead of spinning\\n");
	}
}
"""

if OLD not in src:
    print("FAIL: anchor not found")
    sys.exit(1)
src = src.replace(OLD, NEW, 1)

with open(PATH, "w") as f:
    f.write(src)

print("PATCH OK: gpu_irq boot-arg switch added")
