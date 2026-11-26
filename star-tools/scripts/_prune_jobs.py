import os, shutil, glob

SRC = "/root/star26/s111/work/rootbuild/root/LaunchDaemons"
DST = "/tmp/jobs-keep"
KEEP = """
com.annibale.demo com.annibale.input26 com.annibale.trollstore com.annibale.wifi
com.apple.SpringBoard com.apple.backboardd com.apple.runningboardd com.apple.PosterBoard
com.apple.preboardservice com.apple.preboardservice_v2 com.apple.UserEventAgent-System
com.apple.cfprefsd.xpc.daemon com.apple.cfprefsd.xpc.daemon.system com.apple.distnoted.xpc.daemon
com.apple.notifyd com.apple.configd com.apple.powerd com.apple.sleepd com.apple.logd
com.apple.logd_helper com.apple.syslogd com.apple.aslmanager
com.apple.mobile.usermanagerd com.apple.securityd com.apple.trustd com.apple.tccd
com.apple.security.cloudkeychainproxy3 com.apple.security.cryptexd com.apple.security.swcagent
com.apple.mobile.installd com.apple.containermanagerd com.apple.containermanagerd.system
com.apple.mobile.house_arrest com.apple.mobile.assertion_agent com.apple.lsd com.apple.lskdP7d
com.apple.mobilegestalt.xpc com.apple.assetsd com.apple.managedassetsd
com.apple.iconservices.iconservicesagent com.apple.timed com.apple.timezoneupdates.tzd
com.apple.timesync.audioclocksyncd com.apple.diskarbitrationd com.apple.filesystems.userfsd
com.apple.fseventsd com.apple.mobile.MCInstall com.apple.systemstatusd com.apple.apsd
com.apple.wifid com.apple.mDNSResponder com.apple.audiomxd com.apple.pfd
com.apple.systemstats? com.apple.mobile.notification_proxy com.apple.mobile.insecure_notification_proxy
com.apple.ReportCrash com.apple.ReportSystemMemory com.apple.crash_mover
com.apple.mobile.cache_delete_app_container_caches com.apple.mobile.cache_delete_daily
com.apple.mobile.heartbeat com.apple.deleted_helper com.apple.cache_delete
com.apple.hangreporter com.apple.memory-maintenance com.apple.spindump
com.apple.mobiletimerd com.apple.mobilebackup2
""".split()

os.makedirs(DST, exist_ok=True)
for f in glob.glob(DST + "/*.plist"):
    os.remove(f)

have = set(os.path.basename(p) for p in glob.glob(SRC + "/*.plist"))
kept, missing = [], []
for name in KEEP:
    fn = name + ".plist"
    if fn in have:
        shutil.copy2(os.path.join(SRC, fn), os.path.join(DST, fn))
        kept.append(name)
    else:
        missing.append(name)
# always keep our own jobs
for fn in have:
    if fn.startswith("com.annibale.") and fn not in set(os.path.basename(x) for x in glob.glob(DST + "/*.plist")):
        shutil.copy2(os.path.join(SRC, fn), os.path.join(DST, fn))
        kept.append(fn[:-6])

print("kept %d, missing %d" % (len(kept), len(missing)))
print("missing:", " ".join(sorted(missing)))
