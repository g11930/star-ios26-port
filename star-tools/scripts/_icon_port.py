#!/usr/bin/env python3
"""
Port the minimal v57 icon-fill fix from warsaw-ref into star's inject_sb26.c.
Only fills SBIconImageView.layer.contents from the app bundle's AppIcon PNG.
No glass / wallpaper / notify coupling. Idempotent: safe to run twice.
"""
import os, sys

SRC = '/root/star26/hackios-xnu-userland/userland/src/inject/inject_sb26.c'
BAK = SRC + '.s175-pre-iconfill.bak'

src = open(SRC, encoding='utf-8').read()

if 'sb26_fill_all_icons' in src and 'sb26_icon_minimal_v1' in src:
    print('ALREADY PORTED, nothing to do')
    sys.exit(0)

if not os.path.exists(BAK):
    open(BAK, 'w', encoding='utf-8').write(src)
    print('backup ->', BAK)

# ----- include block: only add what is missing -------------------------------
inc_anchor = None
lines = src.split('\n')
last_inc = -1
for i, l in enumerate(lines):
    if l.startswith('#include'):
        last_inc = i
# insert includes after the last consecutive include near the top (first 60 lines)
for i, l in enumerate(lines[:60]):
    if l.startswith('#include'):
        last_inc = i
need_includes = []
for hdr in ['#include <dirent.h>', '#include <unistd.h>']:
    if hdr not in src:
        need_includes.append(hdr)
if need_includes:
    lines[last_inc+1:last_inc+1] = need_includes
    src = '\n'.join(lines)
    print('added includes:', need_includes)

# ----- helper + fill implementation -----------------------------------------
BLOCK = r'''
/* ===== sb26_icon_minimal_v1: fill home-screen icons from bundle PNGs =====
 * Ported from warsaw-ref v57. The native iconLayerWithInfo path returns nil on
 * 23G90 (ICRIconLayer unimplemented), leaving SBIconImageView.contents empty:
 * the home screen shows labels and no artwork. Read each app bundle's AppIcon
 * PNG and set it on the view's layer ourselves. Deliberately minimal: no glass,
 * no wallpaper, no notify coupling.
 */
static char sb26_icon_key, sb26_icon_image_key;
static unsigned sb26_icons_seen, sb26_icons_filled, sb26_icons_refreshed,
                sb26_icons_no_path, sb26_icons_no_image;

static id sb26_icon_ask(id object, const char *name) {
    SEL sel;
    if (!object) return nil;
    sel = sel_registerName(name);
    if (!class_respondsToSelector(object_getClass(object), sel)) return nil;
    return ((id (*)(id, SEL))objc_msgSend)(object, sel);
}
static const char *sb26_icon_utf8(id string) {
    SEL sel;
    if (!string) return NULL;
    sel = sel_registerName("UTF8String");
    if (!class_respondsToSelector(object_getClass(string), sel)) return NULL;
    return ((const char *(*)(id, SEL))objc_msgSend)(string, sel);
}
static id sb26_icon_uiimage_at(const char *path) {
    Class ui = objc_getClass("UIImage");
    SEL make = sel_registerName("imageWithContentsOfFile:");
    CFStringRef str; id image;
    if (!ui || !class_respondsToSelector(object_getClass((id)ui), make)) return nil;
    str = CFStringCreateWithCString(kCFAllocatorDefault, path, kCFStringEncodingUTF8);
    if (!str) return nil;
    image = ((id (*)(Class, SEL, id))objc_msgSend)(ui, make, (id)str);
    CFRelease(str);
    return image;
}
static id sb26_icon_uiimage_scan(const char *root) {
    DIR *dir = opendir(root); struct dirent *e;
    char sixty[256] = "", any[256] = "", path[PATH_MAX];
    const char *chosen; id image;
    if (!dir) return nil;
    while ((e = readdir(dir)) != NULL) {
        const char *n = e->d_name; size_t len = strlen(n);
        if (len < 5 || len >= sizeof(sixty) || strcmp(n + len - 4, ".png") != 0) continue;
        if (strstr(n, "60x60") && !sixty[0]) snprintf(sixty, sizeof(sixty), "%s", n);
        else if ((strstr(n, "Icon") || strstr(n, "icon")) && !any[0]) snprintf(any, sizeof(any), "%s", n);
    }
    closedir(dir);
    chosen = sixty[0] ? sixty : (any[0] ? any : NULL);
    if (!chosen) return nil;
    if (snprintf(path, sizeof(path), "%s/%s", root, chosen) >= (int)sizeof(path)) return nil;
    image = sb26_icon_uiimage_at(path);
    if (image) fprintf(stderr, "sb26 iconview scan: using %s\n", chosen);
    return image;
}
static void sb26_fill_one_icon(id view) {
    static const char *names[] = {
        "AppIcon60x60@2x.png", "AppIcon60x60@3x.png", "AppIcon76x76@2x.png",
        "SettingsApp60x60@2x.png", "Icon-60@2x.png", "Icon@2x.png", "Icon.png",
        "AppIcon60x60@2x~iphone.png", "icon-60@2x.png",
    };
    id layer, icon, app, base, url, prev, cached, image = nil, cg = nil;
    const char *root, *prev_root; char path[PATH_MAX]; unsigned i; Class tx;

    sb26_icons_seen++;
    layer = sb26_icon_ask(view, "layer");
    if (!layer) return;
    icon = sb26_icon_ask(view, "icon");
    app = sb26_icon_ask(icon, "application");
    if (!app) app = sb26_icon_ask(icon, "applicationProxy");
    base = sb26_icon_ask(app, "bundlePath");
    if (!base) base = sb26_icon_ask(app, "path");
    if (!base) { url = sb26_icon_ask(app, "bundleURL"); base = sb26_icon_ask(url, "path"); }
    root = sb26_icon_utf8(base);
    if (!root) {
        id bid = sb26_icon_ask(icon, "bundleIdentifier");
        Class nb = objc_getClass("NSBundle");
        SEL with = sel_registerName("bundleWithIdentifier:");
        if (!bid) bid = sb26_icon_ask(icon, "applicationBundleIdentifier");
        if (bid && nb && class_respondsToSelector(object_getClass((id)nb), with)) {
            id bundle = ((id (*)(Class, SEL, id))objc_msgSend)(nb, with, bid);
            root = sb26_icon_utf8(sb26_icon_ask(bundle, "bundlePath"));
        }
    }
    if (!root) { sb26_icons_no_path++; return; }

    prev = objc_getAssociatedObject(view, &sb26_icon_key);
    cached = objc_getAssociatedObject(view, &sb26_icon_image_key);
    prev_root = sb26_icon_utf8(prev);
    if (prev_root && cached && strcmp(prev_root, root) == 0) {
        cg = sb26_icon_ask(cached, "CGImage");
        if (cg) sb26_icons_refreshed++; else cached = nil;
    }
    if (!cg) {
        for (i = 0; i < sizeof(names) / sizeof(names[0]); i++) {
            if (snprintf(path, sizeof(path), "%s/%s", root, names[i]) >= (int)sizeof(path)) continue;
            if (access(path, R_OK) != 0) continue;
            image = sb26_icon_uiimage_at(path);
            if (image) break;
        }
        if (!image) image = sb26_icon_uiimage_scan(root);
        if (!image) { sb26_icons_no_image++; return; }
        cg = sb26_icon_ask(image, "CGImage");
        if (!cg) { sb26_icons_no_image++; return; }
        {
            CFStringRef bound = CFStringCreateWithCString(kCFAllocatorDefault, root, kCFStringEncodingUTF8);
            if (bound) {
                objc_setAssociatedObject(view, &sb26_icon_key, (id)bound, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
                CFRelease(bound);
                objc_setAssociatedObject(view, &sb26_icon_image_key, image, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            }
        }
        sb26_icons_filled++;
    }
    tx = objc_getClass("CATransaction");
    if (tx) {
        ((void (*)(Class, SEL))objc_msgSend)(tx, sel_registerName("begin"));
        ((void (*)(Class, SEL, BOOL))objc_msgSend)(tx, sel_registerName("setDisableActions:"), YES);
    }
    ((void (*)(id, SEL, id))objc_msgSend)(layer, sel_registerName("setContents:"), cg);
    ((void (*)(id, SEL, id))objc_msgSend)(layer, sel_registerName("setContentsGravity:"), (id)CFSTR("resizeAspect"));
    if (tx) ((void (*)(Class, SEL))objc_msgSend)(tx, sel_registerName("commit"));
}
static void sb26_fill_icons_recursive(id view, int depth) {
    id subviews; unsigned long count, i; const char *cls;
    if (!view || depth > 14) return;
    cls = class_getName(object_getClass(view));
    if (cls && strstr(cls, "SBIconImageView")) sb26_fill_one_icon(view);
    subviews = sb26_icon_ask(view, "subviews");
    if (!subviews) return;
    if (!class_respondsToSelector(object_getClass(subviews), sel_registerName("count"))) return;
    count = ((unsigned long (*)(id, SEL))objc_msgSend)(subviews, sel_registerName("count"));
    for (i = 0; i < count; i++) {
        id child = ((id (*)(id, SEL, unsigned long))objc_msgSend)(subviews,
            sel_registerName("objectAtIndex:"), i);
        sb26_fill_icons_recursive(child, depth + 1);
    }
}
static void sb26_fill_all_icons(void) {
    Class wc = objc_getClass("UIWindow");
    SEL all = sel_registerName("allWindowsIncludingInternalWindows:onlyVisibleWindows:");
    id windows = nil, app; unsigned long count, i;
    fprintf(stderr, "sb26: iconfill pass enter (wc=%d)\n", wc ? 1 : 0);
    if (wc && class_respondsToSelector(object_getClass((id)wc), all))
        windows = ((id (*)(id, SEL, BOOL, BOOL))objc_msgSend)((id)wc, all, YES, YES);
    if (!windows) {
        app = sb26_icon_ask((id)objc_getClass("UIApplication"), "sharedApplication");
        windows = sb26_icon_ask(app, "windows");
    }
    fprintf(stderr, "sb26: iconfill windows=%d\n", windows ? 1 : 0);
    if (!windows) return;
    count = ((unsigned long (*)(id, SEL))objc_msgSend)(windows, sel_registerName("count"));
    for (i = 0; i < count; i++) {
        id w = ((id (*)(id, SEL, unsigned long))objc_msgSend)(windows,
            sel_registerName("objectAtIndex:"), i);
        sb26_fill_icons_recursive(w, 0);
    }
    fprintf(stderr, "sb26: iconfill: filled=%u seen=%u refilled=%u nopath=%u noimg=%u\n",
        sb26_icons_filled, sb26_icons_seen, sb26_icons_refreshed,
        sb26_icons_no_path, sb26_icons_no_image);
}
static void sb26_icon_late(void *ctx) {
    fprintf(stderr, "sb26: iconfill fire at +%lus\n", (unsigned long)(uintptr_t)ctx);
    sb26_fill_all_icons();
}
static void sb26_schedule_icon_fill(void) {
    static const unsigned long delays[] = { 3, 8, 18, 30, 45, 60, 90, 120, 150 };
    unsigned i;
    for (i = 0; i < sizeof(delays) / sizeof(delays[0]); i++) {
        dispatch_after_f(dispatch_time(DISPATCH_TIME_NOW, (int64_t)delays[i] * NSEC_PER_SEC),
            dispatch_get_main_queue(), (void *)(uintptr_t)delays[i], sb26_icon_late);
    }
    fprintf(stderr, "sb26: iconfill scheduled (%u passes)\n",
            (unsigned)(sizeof(delays) / sizeof(delays[0])));
}
/* ===== end sb26_icon_minimal_v1 ===== */
'''

# insert block before the constructor
ctor_variants = [
    '__attribute__((constructor)) static void\ninstall_sb26(void)',
    '__attribute__((constructor))\nstatic void\ninstall_sb26(void)',
    '__attribute__((constructor)) static void install_sb26(void)',
]
anchor = None
for v in ctor_variants:
    if v in src:
        anchor = v; break
if anchor is None:
    # fallback: before "install_sb26(void)" definition
    idx = src.find('install_sb26(void)')
    if idx < 0:
        print('ERROR: cannot find constructor anchor'); sys.exit(2)
    # find start of that line
    anchor = src[src.rfind('\n', 0, idx)+1:idx]
    if not anchor:
        print('ERROR: bad anchor'); sys.exit(2)

src = src.replace(anchor, BLOCK + '\n' + anchor, 1)
print('inserted icon-fill block before constructor')

# ----- add trigger in constructor --------------------------------------------
# Find the tail of install_sb26: last "Class cal_cls = objc_getClass" block, add after it
trigger = '    sb26_schedule_icon_fill();\n'
marker = 'if (cal_cls) install_calendar_icon_hooks(cal_cls);'
if marker not in src:
    print('ERROR: calendar hook marker not found'); sys.exit(3)
idx = src.find(marker)
# find the closing brace of the following block / the end of that statement line
line_end = src.find('\n', idx)
# insert trigger right after the statement line (before the constructor's closing brace)
src = src[:line_end+1] + trigger + src[line_end+1:]
print('added sb26_schedule_icon_fill() trigger')

open(SRC, 'w', encoding='utf-8').write(src)
print('WROTE', SRC, len(src), 'bytes')
