#!/usr/bin/env python3
"""stage27-oslog-console.py -- put OS_ACTIVITY_DT_MODE=1 into the environment of the two jobs
whose silence hides the boot: SpringBoard and backboardd.

os_log writes to stderr as well when OS_ACTIVITY_DT_MODE is set, and both jobs already have
StandardErrorPath = /dev/console, so every message they log reaches the kernel log.

Nothing else in the image is touched.  Usage: stage27-oslog-console.py ROOTDIR
"""
import plistlib
import sys
import os

WANT = ["com.apple.SpringBoard", "com.apple.backboardd", "com.apple.runningboardd"]
KEY = "OS_ACTIVITY_DT_MODE"


def main(argv):
    root = argv[1]
    for label in WANT:
        path = os.path.join(root, "LaunchDaemons", label + ".plist")
        if not os.path.exists(path):
            print("skip %s: not in the image" % label)
            continue
        with open(path, "rb") as fh:
            d = plistlib.load(fh)
        env = d.get("EnvironmentVariables") or {}
        if env.get(KEY) == "YES":
            print("already set: %s" % label)
            continue
        # mkjobs.py writes YES, and libsystem_oslog reads it as a string
        env[KEY] = "YES"
        d["EnvironmentVariables"] = env
        with open(path, "wb") as fh:
            plistlib.dump(d, fh, fmt=plistlib.FMT_BINARY, sort_keys=True)
        print("%-28s EnvironmentVariables = %s  stderr = %s"
              % (label, sorted(env.items()), d.get("StandardErrorPath")))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
