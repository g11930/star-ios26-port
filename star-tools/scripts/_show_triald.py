import plistlib
p = '/root/star26/s111/work/rootbuild/root/LaunchDaemons/com.apple.triald.plist'
d = plistlib.load(open(p, 'rb'))
for k in ['Label', 'ProgramArguments', 'RunAtLoad', 'KeepAlive', 'MachServices', 'POSIXSpawnType', 'StartInterval', 'ThrottleInterval', 'Rooted', 'EnableTransactions', 'LimitLoadToSessionType']:
    print(k, '=', d.get(k))
print('all keys:', sorted(d.keys()))
