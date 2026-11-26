import io, os, shutil, sys

F = "/root/star26/hackios-xnu-userland/userland/src/inject/inject_sb26.c"
BAK = F + ".s216-iconpatch-pre"

src = io.open(F, "r", encoding="utf-8", newline="").read()
if not os.path.exists(BAK):
    shutil.copy2(F, BAK)
    print("backup ->", BAK)
else:
    print("backup already exists:", BAK)

START = "static IMP original_bitmap_selection;"
END = "static void\nsetup_activation_state(id self, SEL selector)"

i = src.find(START)
j = src.find(END)
if i < 0 or j < 0 or j <= i:
    print("FAIL: markers not found (i=%d j=%d)" % (i, j))
    sys.exit(1)

removed = src[i:j]
print("removing %d bytes, %d lines" % (len(removed), removed.count("\n")))
for must in ("software_bitmap_selection", "install_bitmap_selection", "shouldForceBitmapImages",
             "software_icons_installed", "query_metal_device"):
    print("   contains %-28s %s" % (must, must in removed))

src = src[:i] + src[j:]

call = "    install_bitmap_selection(slide);\n"
if src.count(call) != 1:
    print("FAIL: call site count %d" % src.count(call))
    sys.exit(1)
src = src.replace(call, "")
print("call site removed")

io.open(F, "w", encoding="utf-8", newline="").write(src)
print("\nWROTE", F)

# ---- verify no dangling references ----
left = [l for l in src.splitlines() if any(k in l for k in (
    "original_bitmap_selection", "software_bitmap_selection", "install_bitmap_selection",
    "query_metal_device", "has_metal_device", "metal_device_once",
    "appearance_selector", "glass_selector", "shouldForceBitmapImages", "software_icons_installed"))]
print("\nremaining references:", len(left))
for l in left:
    print("   ", l.strip())

# ---- the rest must still be there ----
for keep in ("setup_activation_state", "install_unlock", "sb26_schedule_icon_fill",
             "install_calendar_icon_hooks", "checked_method(\"SBLockdownManager\"",
             "install_powerdown_hooks"):
    print("keep %-34s %s" % (keep, keep in src))
print("\nlines now:", src.count("\n") + 1)
