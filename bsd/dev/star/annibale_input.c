/*
 * /dev/annibale-touch: a queue of touch samples (see sys/annibale_input.h).
 *
 * Ported from the star reference port's bsd/dev/redwood_input.c, minus the two things this
 * tree does not have: the five-finger escape back to the loader (there is no loader_return()
 * here yet) and the "tl:" latency lines (they went to the loader's log, not the kernel's).
 * A producer -- a touch controller's driver, or a program replaying a script -- writes
 * records; code inside backboardd reads them and synthesizes HID events.
 */
#include <kern/clock.h>
#include <kern/locks.h>
#include <libkern/libkern.h>
#include <miscfs/devfs/devfs.h>
#include <sys/conf.h>
#include <sys/errno.h>
#include <sys/proc.h>
#include <sys/annibale_input.h>
#include <sys/systm.h>
#include <sys/uio.h>
#include <sys/kernel.h>
#include <stdarg.h>

#define TOUCH_QUEUE     512             /* records; a power of two */

static LCK_GRP_DECLARE(touch_lck_grp, "annibale-touch");
static LCK_MTX_DECLARE(touch_lock, &touch_lck_grp);
static struct annibale_touch touch_queue[TOUCH_QUEUE];
static uint32_t touch_head, touch_tail;        /* read from head, add at tail */
static uint32_t touch_posts;                   /* samples ever posted */

extern void annibale_adreno_init(void);
extern void annibale_goodix_init(void);

/*
 * The touch driver's timing lines ("tl: ..."): tl: s (a swap handed over),
 * tl: v (a frame drawn into the panel), tl: l (the panel latched a frame) and
 * "milestone: first_frame".
 *
 * Through loader_log_putc, not printf: this build has CONFIG_NO_PRINTF_STRINGS,
 * so libkern.h makes printf() a `do {} while (0)` and every one of these lines
 * was dropped before it reached the log.  loader_log_putc is the same path the
 * goodix driver's lines take (bsd/dev/star/annibale_goodix.c, goodix_trace),
 * and it works both inside the BSD init and long after, when userland runs.
 * The callers all end their format with "\n"; this adds nothing of its own.
 */
extern void loader_log_putc(char c);

void annibale_tl(const char *format, ...) __printflike(1, 2);

void
annibale_tl(const char *format, ...)
{
	char line[192];
	va_list list;
	int n;

	va_start(list, format);
	n = vsnprintf(line, sizeof(line), format, list);
	va_end(list);
	if (n < 0) {
		return;
	}
	if (n > (int) sizeof(line) - 1) {
		n = (int) sizeof(line) - 1;
	}
	for (int i = 0; i < n; i++) {
		loader_log_putc(line[i]);
	}
}

/* With touch_lock held. */
static void
touch_post_locked(uint32_t type, uint32_t finger, uint32_t x, uint32_t y)
{
	struct annibale_touch *t;

	if (touch_tail - touch_head == TOUCH_QUEUE) {
		touch_head++;                   /* nobody reads: drop the oldest */
	}
	t = &touch_queue[touch_tail++ % TOUCH_QUEUE];
	t->time = mach_absolute_time();
	t->type = type;
	t->finger = finger;
	t->x = x > 65535 ? 65535 : x;
	t->y = y > 65535 ? 65535 : y;
	touch_posts++;
}

void
annibale_touch_post(uint32_t type, uint32_t finger, uint32_t x, uint32_t y)
{
	lck_mtx_lock(&touch_lock);
	touch_post_locked(type, finger, x, y);
	lck_mtx_unlock(&touch_lock);
	wakeup(&touch_queue);
}

static int
touch_open(__unused dev_t dev, __unused int flags, __unused int devtype, __unused struct proc *p)
{
	return 0;
}

static int
touch_close(__unused dev_t dev, __unused int flags, __unused int devtype, __unused struct proc *p)
{
	return 0;
}

static int
touch_read(__unused dev_t dev, struct uio *uio, __unused int ioflag)
{
	struct annibale_touch t;
	int error = 0, moved = 0;

	lck_mtx_lock(&touch_lock);
	while (touch_head == touch_tail) {
		error = msleep(&touch_queue, &touch_lock, PZERO | PCATCH, "annibale-touch", NULL);
		if (error) {
			lck_mtx_unlock(&touch_lock);
			return error;
		}
	}
	while (touch_head != touch_tail && uio_resid(uio) >= (user_ssize_t)sizeof(t)) {
		t = touch_queue[touch_head++ % TOUCH_QUEUE];
		lck_mtx_unlock(&touch_lock);
		error = uiomove((caddr_t)&t, sizeof(t), uio);
		lck_mtx_lock(&touch_lock);
		if (error) {
			break;
		}
		moved++;
	}
	lck_mtx_unlock(&touch_lock);
	return moved ? 0 : error;
}

static int
touch_write(__unused dev_t dev, struct uio *uio, __unused int ioflag)
{
	struct annibale_touch t;

	annibale_goodix_init();          /* started on the first write: the probe's prints then land late enough to be read */
	int error = 0;

	while (uio_resid(uio) >= (user_ssize_t)sizeof(t)) {
		error = uiomove((caddr_t)&t, sizeof(t), uio);
		if (error) {
			break;
		}
		if (t.type < ANNIBALE_TOUCH_DOWN || t.type > ANNIBALE_BUTTON_UP) {
			return EINVAL;
		}
		lck_mtx_lock(&touch_lock);
		touch_post_locked(t.type, t.finger, t.x, t.y);
		lck_mtx_unlock(&touch_lock);
		wakeup(&touch_queue);
	}
	return error;
}

static const struct cdevsw touch_cdevsw = {
	.d_open = touch_open, .d_close = touch_close, .d_read = touch_read, .d_write = touch_write,
	.d_ioctl = eno_ioctl, .d_stop = eno_stop, .d_reset = eno_reset, .d_select = eno_select,
	.d_mmap = eno_mmap, .d_strategy = eno_strat, .d_type = 0
};

void
annibale_input_init(void)
{
	int major = cdevsw_add(-1, &touch_cdevsw);

	if (major < 0 || devfs_make_node(makedev(major, 0), DEVFS_CHAR, UID_ROOT, GID_WHEEL, 0666,
	    "annibale-touch") == NULL) {
		printf("annibale-touch: cannot create the device\n");
	} else {
		printf("annibale-touch: device ready\n");
	}

	annibale_goodix_init();          /* boot-arg touchscreen=1: the FTS touch screen */
	annibale_adreno_init();
}
