PATH = '/root/star26/star-native/bsd/kern/mach_loader.c'
src = open(PATH).read()

# ---------- 1. boot-arg 声明 ----------
anchor = 'extern void star_trace(const char *tag, long long a, long long b);\n'
decl = anchor + '''
/*
 * S92: the initial-page validation loop below clears CS_VALID whenever
 * cs_validate_range() reports !valid or TAINTED.  On star the rootfs binaries
 * are Apple-signed but the first-page hash lookup can legitimately miss in
 * this port, which silently stripped CS_VALID from every exec'd platform
 * binary (cs_flags=0x26000000, SecTask error=22, containermanagerd error 98,
 * backboardd crash loop).
 *
 * star_cs_probe:      1 = emit a star_trace line on each failing initial page.
 * star_cs_keep_valid: 1 = do not clear CS_VALID on initial-page failure.
 * Both default to 0 so behaviour is unchanged unless the boot args opt in.
 */
static int star_cs_probe = 0;
static int star_cs_keep_valid = 0;

static void
star_cs_bootargs(void)
{
\tPE_parse_boot_argn("star_cs_probe", &star_cs_probe, sizeof(star_cs_probe));
\tPE_parse_boot_argn("star_cs_keep_valid", &star_cs_keep_valid, sizeof(star_cs_keep_valid));
}
STARTUP(CODESIGNING, STARTUP_RANK_FIRST, star_cs_bootargs);
'''
assert anchor in src, 'anchor 1 missing'
src = src.replace(anchor, decl, 1)

# ---------- 2. 探针 + 门控（缩进与源文件一致：7 tabs 基准） ----------
old = '\t\t\t\t\t\t\tif (cs_process_global_enforcement() ||\n' \
      '\t\t\t\t\t\t\t    (result->csflags & (CS_HARD | CS_KILL | CS_ENFORCEMENT))) {\n' \
      '\t\t\t\t\t\t\t\tret = LOAD_FAILURE;\n' \
      '\t\t\t\t\t\t\t}\n' \
      '\t\t\t\t\t\t\tresult->csflags &= ~CS_VALID;\n'
new = '\t\t\t\t\t\t\tif (star_cs_probe) {\n' \
      '\t\t\t\t\t\t\t\tstar_trace("CS_INITPAGE_BAD", (long long)(file_offset + off),\n' \
      '\t\t\t\t\t\t\t\t    ((long long)valid << 32) | (long long)(tainted & 0xffffffff));\n' \
      '\t\t\t\t\t\t\t\tstar_trace_s("CS_INITPAGE_F", vp->v_name,\n' \
      '\t\t\t\t\t\t\t\t    (long long)result->csflags);\n' \
      '\t\t\t\t\t\t\t\tstar_trace("CS_INITPAGE_CTX", (long long)alloc_size, (long long)cmds_size);\n' \
      '\t\t\t\t\t\t\t}\n' \
      '\t\t\t\t\t\t\tif (cs_process_global_enforcement() ||\n' \
      '\t\t\t\t\t\t\t    (result->csflags & (CS_HARD | CS_KILL | CS_ENFORCEMENT))) {\n' \
      '\t\t\t\t\t\t\t\tret = LOAD_FAILURE;\n' \
      '\t\t\t\t\t\t\t}\n' \
      '\t\t\t\t\t\t\tif (star_cs_keep_valid) {\n' \
      '\t\t\t\t\t\t\t\t/* S92: keep CS_VALID set; see star_cs_keep_valid above. */\n' \
      '\t\t\t\t\t\t\t} else {\n' \
      '\t\t\t\t\t\t\t\tresult->csflags &= ~CS_VALID;\n' \
      '\t\t\t\t\t\t\t}\n'
assert old in src, 'anchor 2 missing'
src = src.replace(old, new, 1)

open(PATH, 'w').write(src)
print('PATCH OK')
