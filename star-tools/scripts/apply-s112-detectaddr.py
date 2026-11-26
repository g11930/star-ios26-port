import shutil

P = "/root/star26/hackios-xnu-userland/userland/src/inject/inject.c"
shutil.copyfile(P, P + ".s112-pre.bak")
src = open(P).read()

old = "#define CA_DETECT_DISPLAYS      0x1884da264UL   /* -[CAWindowServer _detectDisplays] */"
new = ("/* s112: this image's own offset. s111 loaded the library into backboardd and the check\n"
       " * printed 'found 0x1841a7e18, not what was expected (0x1884da264)' -- the 0x1884da264\n"
       " * table belongs to another iOS build. */\n"
       "#define CA_DETECT_DISPLAYS      0x1841a7e18UL   /* -[CAWindowServer _detectDisplays] */")
if old not in src:
    print("ANCHOR FAIL")
    raise SystemExit(1)
src = src.replace(old, new, 1)
open(P, "w").write(src)
print("PATCHED inject.c")
