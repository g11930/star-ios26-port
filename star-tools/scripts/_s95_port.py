#!/usr/bin/env python3
# 移植 K90 的同步 XPC shim 到 star 的 inject_sb26.c（s95）。
# 严格照搬 K90 已验证形态；SDK 无 xpc/xpc.h，用等价前置声明 + 常量定义替代。
import sys, os, shutil
S = "/root/star26/hackios-xnu-userland/userland/src/inject/inject_sb26.c"
K = "/root/star26/warsaw-ref/userland/src/inject_sb26.c"

s = open(S, encoding="utf-8").read()
k = open(K, encoding="utf-8").read()
if "sb26_hook_xpc_sync" in s:
    print("FAIL: already patched"); sys.exit(1)

# ---- 1) extract K90 shim body: from '#define SB26_XPC_CACHE_MAX' to the line
#         before the interpose table '__attribute__((used, section("__DATA,__interpose")))'
a = k.find("#define SB26_XPC_CACHE_MAX 64")
b = k.find('__attribute__((used, section("__DATA,__interpose")))', a)
if a < 0 or b < 0 or b <= a:
    print("FAIL: K90 shim anchors missing"); sys.exit(1)
shim = k[a:b]
if "sb26_hook_xpc_sync" not in shim or "sb26_dead_note" not in shim:
    print("FAIL: shim body incomplete"); sys.exit(1)
print("shim body: %d lines" % shim.count("\n"))

# ---- 2) XPC declarations (SDK has no <xpc/xpc.h>). Put before shim.
xpc_decl = r'''
/* ---- s95: minimal XPC types for the K90 sync-XPC shim (SDK has no xpc/xpc.h) ---- */
typedef struct xpc_object_s *xpc_object_t;
typedef struct xpc_connection_s *xpc_connection_t;
typedef void (^xpc_reply_block_t)(xpc_object_t);
extern xpc_object_t xpc_dictionary_get_value(xpc_object_t, const char *);
extern int xpc_get_type(xpc_object_t);
extern size_t xpc_data_get_length(xpc_object_t);
extern const void *xpc_data_get_bytes_ptr(xpc_object_t);
extern xpc_object_t xpc_retain(xpc_object_t);
extern void xpc_release(xpc_object_t);
extern char *xpc_copy_description(xpc_object_t);
extern const char *xpc_connection_get_name(xpc_connection_t);
extern xpc_object_t xpc_connection_send_message_with_reply_sync(xpc_connection_t, xpc_object_t);
extern void xpc_connection_send_message_with_reply(xpc_connection_t, xpc_object_t, dispatch_queue_t, xpc_reply_block_t);
extern xpc_object_t xpc_dictionary_create(const char * const *, xpc_object_t *, size_t);
#define XPC_TYPE_DATA ((const void *)1)
#define XPC_TYPE_DICTIONARY ((const void *)2)
#define XPC_TYPE_ERROR ((const void *)3)
/* XPC_TYPE_* are compared by pointer against libxpc's globals; the numeric
 * placeholders above are only to make the macro compile. K90's shim checks
 * xpc_get_type(x) == XPC_TYPE_DICTIONARY/ERROR. We must bind the REAL globals. */
extern const void * const _xpc_type_data;
extern const void * const _xpc_type_dictionary;
extern const void * const _xpc_type_error;
#undef XPC_TYPE_DATA
#undef XPC_TYPE_DICTIONARY
#undef XPC_TYPE_ERROR
#define XPC_TYPE_DATA _xpc_type_data
#define XPC_TYPE_DICTIONARY _xpc_type_dictionary
#define XPC_TYPE_ERROR _xpc_type_error
/* ---- end XPC decl ---- */

'''
# NOTE: the real libxpc global symbol names must be verified before build.
# If they differ, xpc_get_type comparisons will be wrong. We'll verify via nm on libxpc.

# ---- 3) insert before interpose table in star ----
anchor = '__attribute__((used, section("__DATA,__interpose"))) static const struct {'
if anchor not in s:
    print("FAIL: star interpose table anchor missing"); sys.exit(1)
s = s.replace(anchor, xpc_decl + shim + "\n" + anchor, 1)

# ---- 4) add interpose entry ----
old_entry = '    { (const void *)sb26_hook_CFBundleCopyBundleLocalizations, (const void *)CFBundleCopyBundleLocalizations },\n'
new_entry = old_entry + '    { (const void *)sb26_hook_xpc_sync, (const void *)xpc_connection_send_message_with_reply_sync },\n'
if old_entry not in s:
    print("FAIL: interpose entry anchor missing"); sys.exit(1)
s = s.replace(old_entry, new_entry, 1)

shutil.copy2(S, S + ".s95-pre-insert.bak")
open(S, "w", encoding="utf-8").write(s)
print("OK: XPC shim inserted into star inject_sb26.c")
