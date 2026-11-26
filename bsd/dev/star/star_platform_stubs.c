/*
 * star-native platform stubs (stage 0).
 *
 * The K90 release tree's platform drivers are NOT part of this tree.  These
 * entry points still exist because generic kernel files (bsd_init.c,
 * machine_routines.c, loader_return.c) call them; every one is a no-op until
 * the corresponding subsystem is written against star-B.dtb (SM8350).
 * Nothing here touches a device register.
 */
#include <sys/param.h>
#include <sys/systm.h>
#include <sys/types.h>
#include <sys/sysctl.h>
#include <sys/proc.h>
#include <mach/mach_types.h>
#include <mach/mach_time.h>
#include <kern/clock.h>
#include <stdbool.h>

/* The UFSHCI stack registers its counters under kern.annibale; keep the node
 * until the storage layer is renamed for star in stage 1. */
SYSCTL_NODE(_kern, OID_AUTO, annibale, CTLFLAG_RW | CTLFLAG_LOCKED, 0,
    "star stage-0 storage counters");

/* The PMK8550 SPMI path is gone; nothing in this tree writes a PMIC
 * register.  The real disk service is in iokit/Kernel/StarDisk.cpp. */
bool annibale_virtio_blk_dev(dev_t dev) { (void)dev; return false; }

/* annibale_input_init() now lives in bsd/dev/star/annibale_input.c, which creates
 * /dev/annibale-touch and then wakes the GPU, as the reference port's input init did. */
/* star-native has no cpufreq driver yet; the backlight only uses this to suppress
 * its burst log while a touch is in flight, so "never touched" is exact. */
uint64_t annibale_cpufreq_touched(void) { return 0; }
void annibale_audio_init(void) {}
void annibale_virtio_blk_init(void) {}
void annibale_sparse_init(void) {}
bool annibale_gpu_stub_start(void) { return true; }
void annibale_apfs_check_init(void) {}

void adreno8_quiesce(void) {}
void adreno8_return_quiesce(void) {}
void annibale_wifi_stop(void) {}
void annibale_wifi_quiesce(void) {}
void annibale_haptic_quiesce(void) {}
void annibale_torch_quiesce(void) {}
bool annibale_iris_return_quiesce(void) { return true; }
void star_display_quiesce(void) {}
void star_display_poweroff(void) {}
void star_iosurface_usage(uint32_t *count, uint64_t *bytes)
{
	if (count) { *count = 0; }
	if (bytes) { *bytes = 0; }
}

/*
 * kern.annibale.say: the line any process writes here goes into the kernel log as
 * "say PID TEXT".
 *
 * Why it exists here (stage 0 did not have it): every annibale library in the iOS 26
 * userland reports through this sysctl, not through standard error --
 * src/inject/inject_sb26.c (sb26_log_self_uuid), sb_metal_registration_sequence.inc,
 * inject_sb26_layers.c, inject_sb26_rate.c, inject_posterboard.c, inject_media.c and
 * src/inject/xpcwatch.c all call
 *     sysctlbyname("kern.annibale.say", NULL, NULL, line, strlen(line) + 1)
 * because the processes they are inserted into are started by launchd with no terminal
 * ("an XPC service under xpcproxy, a sandboxed extension").  The K90 tree keeps the
 * writer in bsd/dev/annibale/annibale_threads.c; star-native carries no bsd/dev/annibale,
 * so the node was registered for the UFS counters above and nothing answered this name:
 * every one of those diagnostics was silently dropped (ENOENT), which is why
 * "sb26: loaded in ..." never appeared and the SpringBoard question could not be
 * answered from the log.
 *
 * Text only, 256 bytes a line, at most STAR_SAY_PER_SECOND lines a second so a library
 * that says too much cannot spend the log on itself.  IOLog, not printf(): this build
 * has CONFIG_NO_PRINTF_STRINGS, so printf() is empty and its format strings are gone.
 */
extern void IOLog(const char *format, ...) __printflike(1, 2);

#define STAR_SAY_PER_SECOND 200

static int
star_say_sysctl(__unused struct sysctl_oid *oidp, __unused void *arg1, __unused int arg2,
    struct sysctl_req *req)
{
	static uint64_t window;
	static uint32_t said;
	char text[256];
	size_t length;
	uint64_t now, second;
	int error;

	if (req->newptr == USER_ADDR_NULL) {
		return 0;
	}
	length = req->newlen < sizeof(text) - 1 ? (size_t)req->newlen : sizeof(text) - 1;
	error = SYSCTL_IN(req, text, length);
	if (error != 0) {
		return error;
	}
	text[length] = '\0';
	while (length > 0 && (text[length - 1] == '\n' || text[length - 1] == '\0')) {
		text[--length] = '\0';
	}
	nanoseconds_to_absolutetime(NSEC_PER_SEC, &second);
	now = mach_absolute_time();
	if (now - window >= second) {
		window = now;
		said = 0;
	}
	if (++said > STAR_SAY_PER_SECOND) {
		return 0;
	}
	IOLog("say %d %s\n", proc_selfpid(), text);
	return 0;
}

SYSCTL_PROC(_kern_annibale, OID_AUTO, say,
    CTLTYPE_STRING | CTLFLAG_WR | CTLFLAG_ANYBODY | CTLFLAG_LOCKED,
    NULL, 0, star_say_sysctl, "A",
    "a line for the kernel log, from any process");

/*
 * kern.annibale.env: the words PROCESS:NAME=VALUE that the userland driver reads at load
 * (tools/userland-driver/annibalemetal_diag.inc rw_runtime_env) and puts into its own
 * environment before the first Metal device is made. The read side has existed for a while;
 * this kernel exported no such name, so every setting had to come from the launchd plist.
 *
 * The default below is the one measurement that matters here: Mesa's shader cache is compiled
 * into libannibaleair.dylib (get_disk_shader_cache, MESA_SHADER_CACHE_DIR) but had no directory,
 * so every IR3 compile -- 40 to 575 ms of SpringBoard's main thread -- was thrown away.
 */
static char annibale_env_conf[512] =
    "SpringBoard:MESA_SHADER_CACHE_DIR=/var/mobile/Library/Caches/mesa-annibale "
    "backboardd:MESA_SHADER_CACHE_DIR=/var/mobile/Library/Caches/mesa-annibale "
    "iconservicesagent:MESA_SHADER_CACHE_DIR=/var/mobile/Library/Caches/mesa-annibale "
    "WidgetRenderer_Default:MESA_SHADER_CACHE_DIR=/var/mobile/Library/Caches/mesa-annibale "
    "Preferences:MESA_SHADER_CACHE_DIR=/var/mobile/Library/Caches/mesa-annibale";

SYSCTL_STRING(_kern_annibale, OID_AUTO, env,
    CTLFLAG_RW | CTLFLAG_ANYBODY | CTLFLAG_LOCKED, annibale_env_conf, sizeof(annibale_env_conf),
    "PROCESS:NAME=VALUE words for the userland driver");

/*
 * The same words, for exec: a sandboxed program can be refused the sysctl read (iconservicesagent
 * was), but the environment exec builds is in place before dyld and nothing can take it away.
 */
const char *
star_annibale_env_words(void)
{
	return annibale_env_conf;
}
