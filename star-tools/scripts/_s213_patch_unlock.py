#!/usr/bin/env python3
# s213: port K90 new unlock logic into star inject_sb26.c
# Only touches unlock core; keeps star's icon rendering / refresh / wifi / localization / fallback hook.
P = "/root/star26/hackios-xnu-userland/userland/src/inject/inject_sb26.c"

s = open(P, "r", encoding="utf-8").read()
orig = s

def rep(old, new, tag):
    global s
    n = s.count(old)
    if n != 1:
        raise SystemExit("ABORT [%s] old count=%d (expected 1)" % (tag, n))
    s = s.replace(old, new, 1)
    print("OK   [%s]" % tag)

# ---- 1a: unlock source 24 -> 25 (iOS 26 CoverSheet) ----
rep(
r'''/* What the cover sheet passes to -[SBLockScreenManager unlockUIFromSource:withOptions:] on 16.5. */
#define UNLOCK_SOURCE_COVER_SHEET 24''',
r'''/* CoverSheet unlock source on iOS 26. */
#define UNLOCK_SOURCE_COVER_SHEET 25''',
"source-24-to-25")

# ---- 1b: timing constants ----
rep(
r'''#define UNLOCK_FIRST_SECONDS 4
#define UNLOCK_EVERY_SECONDS 1
#define UNLOCK_ATTEMPTS 60''',
r'''#define UNLOCK_FIRST_SECONDS 2
#define UNLOCK_EVERY_SECONDS 1
#define UNLOCK_ATTEMPTS 120''',
"timing-constants")

# ---- 2: insert K90 helper chain before unlock_once ----
REP2_OLD = r'''    if (class_getInstanceMethod(bl_cls, turn_on))
        ((void (*)(id, SEL, long))objc_msgSend)(bl, turn_on, 1);
    sb26_sync_initial_brightness(1);
}

static int
unlock_once(const char *why)'''

REP2_NEW = r'''    if (class_getInstanceMethod(bl_cls, turn_on))
        ((void (*)(id, SEL, long))objc_msgSend)(bl, turn_on, 1);
    sb26_sync_initial_brightness(1);
}

/* ===== s213: K90 new unlock wait chain (CoverSheet appear + layout element) ===== */
static unsigned boot_unlock_wait_appear;

static id
object_if_responds(id object, const char *name)
{
    SEL selector = sel_registerName(name);
    if (!object || !class_respondsToSelector(object_getClass(object), selector)) return nil;
    return ((id (*)(id, SEL))objc_msgSend)(object, selector);
}

static id
home_screen_controller(void)
{
    Class cls = objc_getClass("SBIconController");
    SEL shared = sel_registerName("sharedInstanceIfExists");
    if (!cls || !class_getClassMethod(cls, shared)) return nil;
    return object_if_responds(((id (*)(Class, SEL))objc_msgSend)(cls, shared), "_mainDisplayHomeScreenController");
}

/*
 * SBHomeScreenController holds icons and widgets back while iconOcclusionReasons carries the lock
 * screen's bit 0x10. Two writers race at boot: the SBLockScreenUIWillDismissNotification handler
 * clears the bit, and the display layout publisher's observer queues a block to the main queue
 * with the mask of the layout it was called with, which sets the bit again when that layout still
 * held com.apple.lock-screen. Wait until the published layout holds the lock screen's element.
 * 1: it does; 0: not yet; -1: this build has no such getters.
 */
static int
lock_screen_layout_published(void)
{
    id publisher = object_if_responds(object_if_responds(home_screen_controller(), "windowScene"),
        "displayLayoutPublisher");
    if (!publisher || !class_respondsToSelector(object_getClass(publisher), sel_registerName("currentLayout")))
        return -1;
    id elements = object_if_responds(object_if_responds(publisher, "currentLayout"), "elements");
    if (!elements || !class_respondsToSelector(object_getClass(elements), sel_registerName("objectAtIndex:")))
        return 0;
    unsigned long count = ((unsigned long (*)(id, SEL))objc_msgSend)(elements, sel_registerName("count"));
    for (unsigned long i = 0; i < count; i++) {
        id element = ((id (*)(id, SEL, unsigned long))objc_msgSend)(elements, sel_registerName("objectAtIndex:"), i);
        id identifier = object_if_responds(element, "identifier");
        const char *text = identifier
            ? ((const char *(*)(id, SEL))objc_msgSend)(identifier, sel_registerName("UTF8String")) : NULL;
        if (text && !strcmp(text, "com.apple.lock-screen")) return 1;
    }
    return 0;
}

/* What the race above left behind, a few seconds after the unlock: 0 is the settled home screen. */
static void
report_icon_occlusion(void *context)
{
    (void)context;
    id home = home_screen_controller();
    SEL reasons = sel_registerName("iconOcclusionReasons");
    if (!home || !class_respondsToSelector(object_getClass(home), reasons)) {
        fprintf(stderr, "sb26: icons: no home screen controller to read iconOcclusionReasons from\n");
        return;
    }
    fprintf(stderr, "sb26: icons: occlusion reasons %#llx, lock screen element in the layout %d\n",
        ((unsigned long long (*)(id, SEL))objc_msgSend)(home, reasons), lock_screen_layout_published());
}

#define LAYOUT_WAITS 20
static unsigned boot_unlock_wait_layout;
static int boot_unlock_layout_seen;

static int
unlock_once(const char *why)'''
rep(REP2_OLD, REP2_NEW, "helper-chain")

# ---- 3: unlock_once wait logic + return 2 on success ----
REP3_OLD = r'''    wake_screen_for_unlock();
    BOOL answer = ((BOOL (*)(id, SEL, long, id))objc_msgSend)(manager, unlock_ui, UNLOCK_SOURCE_COVER_SHEET, nil);
    int locked_after = ((BOOL (*)(id, SEL))objc_msgSend)(manager, locked);
    fprintf(stderr, "sb26: unlock %s: answer=%d locked_after=%d\n", why, answer, locked_after);
    if (!locked_after) {
        sb26_on_unlocked();
    }
    return 1;
}'''

REP3_NEW = r'''    wake_screen_for_unlock();
    /* s213: wait for CoverSheet appearance + published lock-screen layout (K90 race fix). */
    Class cspm_cls = objc_getClass("SBCoverSheetPresentationManager");
    SEL shared_if_exists = sel_registerName("sharedInstanceIfExists");
    id cspm = (cspm_cls && class_getClassMethod(cspm_cls, shared_if_exists))
        ? ((id (*)(Class, SEL))objc_msgSend)(cspm_cls, shared_if_exists) : nil;
    id sliding = nil;
    if (cspm) {
        SEL sliding_if_loaded_sel = sel_registerName("coverSheetSlidingViewControllerIfLoaded");
        SEL sliding_sel = sel_registerName("coverSheetSlidingViewController");
        if (class_respondsToSelector(object_getClass(cspm), sliding_if_loaded_sel)) {
            sliding = ((id (*)(id, SEL))objc_msgSend)(cspm, sliding_if_loaded_sel);
        } else if (class_respondsToSelector(object_getClass(cspm), sliding_sel)) {
            sliding = ((id (*)(id, SEL))objc_msgSend)(cspm, sliding_sel);
        }
    }
    SEL appear_sel = sel_registerName("_appearState");
    int32_t appear = (sliding && class_respondsToSelector(object_getClass(sliding), appear_sel))
        ? ((int32_t (*)(id, SEL))objc_msgSend)(sliding, appear_sel) : -1;
    if (appear != 2) {
        boot_unlock_wait_appear++;
        fprintf(stderr, "sb26: unlock %s: waiting for CoverSheet _appearState==2 (appear=%d wait=%u)\n",
            why, appear, boot_unlock_wait_appear);
        return 1;
    }
    int published = lock_screen_layout_published();
    if (published == 0 && boot_unlock_wait_layout < LAYOUT_WAITS) {
        boot_unlock_wait_layout++;
        fprintf(stderr, "sb26: unlock %s: waiting for the lock screen's layout element (wait=%u)\n",
            why, boot_unlock_wait_layout);
        return 1;
    }
    if (published == 1 && !boot_unlock_layout_seen) {
        /* The observer's block for this layout is on the main queue behind us: unlock on the next attempt. */
        boot_unlock_layout_seen = 1;
        return 1;
    }
    if (published != 1) {
        fprintf(stderr, "sb26: unlock %s: unlocking without the lock screen's layout element (state=%d wait=%u)\n",
            why, published, boot_unlock_wait_layout);
    }
    BOOL answer = ((BOOL (*)(id, SEL, long, id))objc_msgSend)(manager, unlock_ui, UNLOCK_SOURCE_COVER_SHEET, nil);
    int locked_after = ((BOOL (*)(id, SEL))objc_msgSend)(manager, locked);
    fprintf(stderr, "sb26: unlock %s: answer=%d locked_after=%d\n", why, answer, locked_after);
    if (!locked_after) {
        sb26_on_unlocked();
        return 2;
    }
    return 1;
}'''
rep(REP3_OLD, REP3_NEW, "unlock_once-wait")

# ---- 4: boot_unlock completion condition + retry interval ----
REP4_OLD = r'''    int state = unlock_once("boot");
    if (state == 1) boot_unlock_seen_locked = 1;
    if (state == 0 && boot_unlock_seen_locked) {
        fprintf(stderr, "sb26: boot unlock done after %lu attempts\n", (unsigned long)attempt);
        sb26_on_unlocked();
        return;
    }
    if (attempt >= UNLOCK_ATTEMPTS) {
        fprintf(stderr, "sb26: boot unlock gave up after %lu attempts, lock screen seen=%d\n",
            (unsigned long)attempt, boot_unlock_seen_locked);
        return;
    }
    dispatch_after_f(dispatch_time(DISPATCH_TIME_NOW, UNLOCK_EVERY_SECONDS * NSEC_PER_SEC),
        dispatch_get_main_queue(), (void *)attempt, boot_unlock);'''

REP4_NEW = r'''    int state = unlock_once("boot");
    if (state >= 1) boot_unlock_seen_locked = 1;
    if (state == 2 || (state == 0 && boot_unlock_seen_locked)) {
        fprintf(stderr, "sb26: boot unlock done after %lu attempts\n", (unsigned long)attempt);
        sb26_on_unlocked();
        dispatch_after_f(dispatch_time(DISPATCH_TIME_NOW, 3 * NSEC_PER_SEC), dispatch_get_main_queue(), NULL,
            report_icon_occlusion);
        return;
    }
    if (attempt >= UNLOCK_ATTEMPTS) {
        fprintf(stderr, "sb26: boot unlock gave up after %lu attempts, lock screen seen=%d\n",
            (unsigned long)attempt, boot_unlock_seen_locked);
        return;
    }
    int64_t delay_ns = (state == 1) ? (NSEC_PER_SEC / 2) : (UNLOCK_EVERY_SECONDS * NSEC_PER_SEC);
    dispatch_after_f(dispatch_time(DISPATCH_TIME_NOW, delay_ns),
        dispatch_get_main_queue(), (void *)attempt, boot_unlock);'''
rep(REP4_OLD, REP4_NEW, "boot_unlock-condition")

if s == orig:
    raise SystemExit("ABORT: no change")
open(P, "w", encoding="utf-8").write(s)
print("WRITE OK, %d -> %d bytes" % (len(orig), len(s)))
