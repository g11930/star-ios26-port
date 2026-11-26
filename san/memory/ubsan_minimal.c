/*
 * Copyright (c) 2021 Apple Inc. All rights reserved.
 *
 * @APPLE_OSREFERENCE_LICENSE_HEADER_START@
 *
 * This file contains Original Code and/or Modifications of Original Code
 * as defined in and that are subject to the Apple Public Source License
 * Version 2.0 (the 'License'). You may not use this file except in
 * compliance with the License. The rights granted to you under the License
 * may not be used to create, or enable the creation or redistribution of,
 * unlawful or unlicensed copies of an Apple operating system, or to
 * circumvent, violate, or enable the circumvention or violation of, any
 * terms of an Apple operating system software license agreement.
 *
 * Please obtain a copy of the License at
 * http://www.opensource.apple.com/apsl/ and read it before using this file.
 *
 * The Original Code and all software distributed under the License are
 * distributed on an 'AS IS' basis, WITHOUT WARRANTY OF ANY KIND, EITHER
 * EXPRESS OR IMPLIED, AND APPLE HEREBY DISCLAIMS ALL SUCH WARRANTIES,
 * INCLUDING WITHOUT LIMITATION, ANY WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE, QUIET ENJOYMENT OR NON-INFRINGEMENT.
 * Please see the License for the specific language governing rights and
 * limitations under the License.
 *
 * @APPLE_OSREFERENCE_LICENSE_HEADER_END@
 */

/*
 * UBSan minimal runtime for production environments
 * This runtime emulates an inlined trap model, but gated through the
 * logging functions, so that fix and continue is always possible just by
 * advancing the program counter.
 * NOTE: this file is regularly instrumented, since all helpers must inline
 * correctly to a trap.
 */
#include <sys/sysctl.h>
#include <kern/kalloc.h>
#include <kern/trap_telemetry.h>
#include <machine/machine_routines.h>
#include <mach/machine/thread_status.h>
#include <san/ubsan_minimal.h>

#define UBSAN_M_NONE            (0x0000)
#define UBSAN_M_PANIC           (0x0001)

#define UBSAN_MINIMAL_TRAPS_START       UBSAN_SOFT_TRAP_SIGNED_OF
#define UBSAN_MINIMAL_TRAPS_END         UBSAN_SOFT_TRAP_SIGNED_OF

struct ubsan_minimal_trap_desc {
	uint16_t        id;
	uint32_t        flags;
	char            str[16];
};

#if RELEASE
static __security_const_late
#endif /* RELEASE */
struct ubsan_minimal_trap_desc ubsan_traps[] = {
	{ UBSAN_SOFT_TRAP_SIGNED_OF, UBSAN_M_NONE, "signed-overflow" },
};

static SECURITY_READ_ONLY_LATE(bool) ubsan_minimal_enabled = false;

/* Helper counters for fixup/drop operations */
static uint32_t ubsan_minimal_fixup_events;

static char *
ubsan_minimal_trap_to_str(uint16_t trap)
{
	return ubsan_traps[trap - UBSAN_MINIMAL_TRAPS_START].str;
}

void
ubsan_handle_brk_trap(
	void              *state,
	uint16_t          trap)
{
	if (!ubsan_minimal_enabled) {
#if DEVELOPMENT
		/*
		 * We want to know about those sooner than later...
		 *
		 * panic() records __builtin_return_address(0) as the caller, and
		 * inside this file that address is the cold block around this call,
		 * so it never names the instruction that took the brk. state is the
		 * arm_saved_state_t the exception vector spilled before any C
		 * handler ran: pc is ELR_EL1, lr is x30, fp is x29 and esr is
		 * ESR_EL1, all as the trap took them.
		 *
		 * The brk lives in the __ubsan_handle_*_minimal stubs below, so pc
		 * names the stub and not the check that called it. The call into the
		 * stub is a plain branch, so lr points past it inside the
		 * instrumented function, and fp is that function's frame. ESR_EL1
		 * carries the exception class and the ISS comment, which separates
		 * the UBSAN checks.
		 *
		 * These fields describe the trap being handled right now. They stay
		 * valid only for the duration of this handler, this early before the
		 * full UBSAN runtime can report sites.
		 */
		arm_saved_state_t *ss = (arm_saved_state_t *)state;
		uint64_t elr = 0, lr = 0, fp = 0, esr = 0;

		if (is_saved_state64(ss)) {
			elr = const_saved_state64(ss)->pc;
			lr = const_saved_state64(ss)->lr;
			fp = const_saved_state64(ss)->fp;
			esr = const_saved_state64(ss)->esr;
		}

		panic("UBSAN trap taken in early startup code: trap=%#x elr=%p lr=%p fp=%p esr=%#llx",
		    trap, (void *)(uintptr_t)elr, (void *)(uintptr_t)lr,
		    (void *)(uintptr_t)fp, (unsigned long long)esr);
#endif /* DEVELOPMENT */
		return;
	}

	uint32_t trap_idx = trap - UBSAN_MINIMAL_TRAPS_START;

	if (ubsan_traps[trap_idx].flags & UBSAN_M_PANIC) {
		panic("UBSAN trap for %s detected\n", ubsan_minimal_trap_to_str(trap));
		__builtin_unreachable();
	}

	ubsan_minimal_fixup_events++;
}

__startup_func
void
ubsan_minimal_init(void)
{
#if DEVELOPMENT || DEBUG
	bool force_panic = false;
	PE_parse_boot_argn("-ubsan_force_panic", &force_panic, sizeof(force_panic));
	if (force_panic) {
		for (int i = UBSAN_MINIMAL_TRAPS_START; i <= UBSAN_MINIMAL_TRAPS_END; i++) {
			size_t idx = i - UBSAN_MINIMAL_TRAPS_START;
			ubsan_traps[idx].flags |= UBSAN_M_PANIC;
		}
	}
#endif /* DEVELOPMENT || DEBUG */

	ubsan_minimal_enabled = true;
}

#if DEVELOPMENT || DEBUG

/* Add a simple testing path that explicitly triggers a signed int overflow */
static int
sysctl_ubsan_test SYSCTL_HANDLER_ARGS
{
#pragma unused(oidp, arg1, arg2)
	int err, incr = 0;
	err = sysctl_io_number(req, 0, sizeof(int), &incr, NULL);

	int k = 0x7fffffff;

	for (int i = 0; i < 3; i++) {
		int a = k;
		if (incr != 0) {
			k += incr;
		}

		k = a;
	}

	return err;
}

SYSCTL_DECL(kern_ubsan);
SYSCTL_NODE(_kern, OID_AUTO, ubsan, CTLFLAG_RW | CTLFLAG_LOCKED, 0, "ubsan");
SYSCTL_NODE(_kern_ubsan, OID_AUTO, minimal, CTLFLAG_RW | CTLFLAG_LOCKED, 0, "minimal runtime");
SYSCTL_INT(_kern_ubsan_minimal, OID_AUTO, fixups, CTLFLAG_RW | CTLFLAG_LOCKED, &ubsan_minimal_fixup_events, 0, "");
SYSCTL_INT(_kern_ubsan_minimal, OID_AUTO, signed_ovf_flags, CTLFLAG_RW | CTLFLAG_LOCKED, &(ubsan_traps[0].flags), 0, "");
SYSCTL_PROC(_kern_ubsan_minimal, OID_AUTO, test, CTLTYPE_INT | CTLFLAG_RW | CTLFLAG_LOCKED,
    0, 0, sysctl_ubsan_test, "I", "Test signed overflow detection");

#endif /* DEVELOPMENT || DEBUG */

#define UBSAN_M_ATTR    __attribute__((always_inline, cold))

UBSAN_M_ATTR void
__ubsan_handle_divrem_overflow_minimal(void)
{
	asm volatile ("brk #%0" : : "i"(UBSAN_SOFT_TRAP_SIGNED_OF));
}

UBSAN_M_ATTR void
__ubsan_handle_negate_overflow_minimal(void)
{
	asm volatile ("brk #%0" : : "i"(UBSAN_SOFT_TRAP_SIGNED_OF));
}

UBSAN_M_ATTR void
__ubsan_handle_mul_overflow_minimal(void)
{
	asm volatile ("brk #%0" : : "i"(UBSAN_SOFT_TRAP_SIGNED_OF));
}

UBSAN_M_ATTR void
__ubsan_handle_sub_overflow_minimal(void)
{
	asm volatile ("brk #%0" : : "i"(UBSAN_SOFT_TRAP_SIGNED_OF));
}

UBSAN_M_ATTR void
__ubsan_handle_add_overflow_minimal(void)
{
	asm volatile ("brk #%0" : : "i"(UBSAN_SOFT_TRAP_SIGNED_OF));
}
