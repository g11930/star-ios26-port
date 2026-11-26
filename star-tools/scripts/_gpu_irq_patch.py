#!/usr/bin/env python3
"""方案 A 第 2 步补丁：在 annibale_adreno.c 实现 annibale_gpu_irqs/gpu_pause 强定义 + 注册 GPU 完成 ISR。"""
import sys

PATH = "/root/star26/star-native/bsd/dev/star/annibale_adreno.c"

with open(PATH, "r") as f:
    src = f.read()

# ---- 补丁 1：在 annibale_gpu_done 之后插入 ISR/irqs/pause/attach ----
OLD1 = """/* How far the 3D core has got. */
bool
annibale_gpu_done(uint32_t fence)
{
	volatile uint32_t *word = (volatile uint32_t *)(core_scratch.memory + GPU_FENCE_AT);

	to_memory((vm_offset_t)word, 4);
	return (int32_t)(*word - fence) >= 0;
}

uint32_t
annibale_gpu_last(void)
"""

NEW1 = """/* How far the 3D core has got. */
bool
annibale_gpu_done(uint32_t fence)
{
	volatile uint32_t *word = (volatile uint32_t *)(core_scratch.memory + GPU_FENCE_AT);

	to_memory((vm_offset_t)word, 4);
	return (int32_t)(*word - fence) >= 0;
}

/*
 * The GPU's completion interrupt (the 3D core's, wired in the device tree as kgsl_3d0_irq:
 * GIC SPI 0x12c, level-triggered). The interrupt is quieted where it is raised -- the GMU's
 * GMU2HOST register -- and each arrival is counted, so a waiter can tell one has come without
 * reading a register in a loop.
 */
static uint32_t gpu_irq_count;                  /* completion interrupts that have come */

/* gic_v3_spi_attach() has no header of its own; the kernel's GIC v3 driver declares it here. */
extern kern_return_t gic_v3_spi_attach(uint32_t intid, bool edge,
    void (*handler)(void *context, uint32_t intid), void *context);

static void
gpu_completion_isr(void *context, uint32_t intid)
{
	(void) context;
	(void) intid;
	wr(gmu.base + GMU_GMU2HOST_INTR_CLR, 0xffffffffu);   /* quiet the level-triggered source */
	__atomic_fetch_add(&gpu_irq_count, 1u, __ATOMIC_RELAXED);
}

/* How many completion interrupts have come so far (0 where there are none). */
uint32_t
annibale_gpu_irqs(void)
{
	return __atomic_load_n(&gpu_irq_count, __ATOMIC_RELAXED);
}

/*
 * Between two looks at annibale_gpu_done(): sleep until the next completion interrupt after
 * `seen`, at most longest_us; without interrupts, poll_us at a time. The sleep lets the
 * processor go to other work (the touch events, the timers) instead of spinning; if the
 * interrupt never arrives the wait simply runs its longest_us and the caller looks again.
 */
void
annibale_gpu_pause(uint32_t seen, uint32_t poll_us, uint32_t longest_us)
{
	uint32_t rounds = longest_us / poll_us;

	if (rounds == 0) {
		rounds = 1;
	}
	for (uint32_t round = 0; round < rounds; round++) {
		if (__atomic_load_n(&gpu_irq_count, __ATOMIC_RELAXED) != seen) {
			return;           /* the interrupt has come */
		}
		sleep_us(poll_us);
	}
}

/* Attach the GPU's completion interrupt; a failure leaves the waiter sleeping its longest_us. */
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

uint32_t
annibale_gpu_last(void)
"""

if OLD1 not in src:
    print("FAIL: patch 1 anchor not found")
    sys.exit(1)
src = src.replace(OLD1, NEW1, 1)

# ---- 补丁 2：在 AnnibaleGPUStartReal() 调用前挂接 ISR ----
OLD2 = """\t\t\tAnnibaleGPUStartReal();
\t\t\treturn;
"""
NEW2 = """\t\t\tattach_gpu_completion_irq();
\t\t\tAnnibaleGPUStartReal();
\t\t\treturn;
"""

if OLD2 not in src:
    print("FAIL: patch 2 anchor not found")
    sys.exit(1)
src = src.replace(OLD2, NEW2, 1)

with open(PATH, "w") as f:
    f.write(src)

print("PATCH OK")
