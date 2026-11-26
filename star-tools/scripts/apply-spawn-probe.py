#!/usr/bin/env python3
"""
s64: add minimal spawn-path trace points to bsd/kern/kern_exec.c.

Only star_trace() calls (hand-built hex -> loader_log_line, no printf). No logic
changes. Idempotent: re-running with --check or again does nothing if markers
are present. Goal: find out why xpcproxy (loaded 55x) never exec's cfprefsd etc.

Trace points:
  SPWNVAL  - spawn_validate_persona: pspi_id / pspi_flags
  SPWNADOPT- spawn_persona_adopt: persona missing branch reached (the fallback)
  SPWNRET  - posix_spawn final error / exec_done / spawn_no_exec
"""
import sys, os, shutil

K = "/root/star26/star-native/bsd/kern/kern_exec.c"
BAK = K + ".s63.bak"

def main():
    with open(K, "r", encoding="utf-8") as f:
        src = f.read()

    check_only = "--check" in sys.argv

    markers = ["SPWNVAL", "SPWNADOPT", "SPWNRET"]
    present = {m: (m in src) for m in markers}

    if check_only:
        print("check:", present)
        return 0 if all(present.values()) else 1

    if all(present.values()):
        print("all markers already present; nothing to do")
        return 0

    if not os.path.exists(BAK):
        shutil.copy2(K, BAK)
        print("backup ->", BAK)

    # 1) spawn_validate_persona: trace pspi_id / pspi_flags at entry.
    a1 = """spawn_validate_persona(struct _posix_spawn_persona_info *px_persona)
{
	int error = 0;
	struct persona *persona = NULL;
"""
    b1 = """spawn_validate_persona(struct _posix_spawn_persona_info *px_persona)
{
	int error = 0;
	struct persona *persona = NULL;

	star_trace("SPWNVAL", (long long)px_persona->pspi_id, (long long)px_persona->pspi_flags);
"""
    # 2) spawn_persona_adopt: fallback branch (persona == NULL).
    a2 = """	persona = persona_lookup(px_persona->pspi_id);
	if (!persona) {
		/*
		 * star: there are no personas in this port"""
    b2 = """	persona = persona_lookup(px_persona->pspi_id);
	if (!persona) {
		star_trace("SPWNADOPT", (long long)px_persona->pspi_id, (long long)px_persona->pspi_uid);
		/*
		 * star: there are no personas in this port"""
    # 3) posix_spawn: final return, before "return error;".
    a3 = """	assert(spawn_no_exec || exec_failure_reason == NULL);
	return error;
}

/*
 * proc_exec_switch_task"""
    b3 = """	assert(spawn_no_exec || exec_failure_reason == NULL);
	star_trace("SPWNRET", (long long)error, (long long)((exec_done ? 1 : 0) | (spawn_no_exec ? 2 : 0)));
	return error;
}

/*
 * proc_exec_switch_task"""

    for name, a, b, m in (("validate", a1, b1, "SPWNVAL"),
                          ("adopt", a2, b2, "SPWNADOPT"),
                          ("return", a3, b3, "SPWNRET")):
        if present[m]:
            print(name, "already present, skip")
            continue
        n = src.count(a)
        if n != 1:
            print("ERROR: anchor", name, "occurrences =", n, "; abort (no partial write)")
            return 2
        src = src.replace(a, b, 1)
        print(name, "patched")

    with open(K, "w", encoding="utf-8") as f:
        f.write(src)
    print("written", K)
    return 0

if __name__ == "__main__":
    sys.exit(main())
