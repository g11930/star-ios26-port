import sys
p = sys.argv[1] if len(sys.argv) > 1 else "/tmp/s126b.txt"
pat = sys.argv[2] if len(sys.argv) > 2 else "runningboardd[30"
t0 = sys.argv[3] if len(sys.argv) > 3 else ""
t1 = sys.argv[4] if len(sys.argv) > 4 else ""
ls = [l for l in open(p, 'rb').read().decode('utf-8', 'replace').replace('\0', '').split('\n') if pat in l]
ls.sort(key=lambda l: l[:24])
sel = [l for l in ls if (not t0 or l[:24] >= t0) and (not t1 or l[:24] <= t1)]
print("total %d, selected %d" % (len(ls), len(sel)))
# 只打印时间戳 + "消息类型"（去掉私有细节）
for l in sel:
    ts = l[:24]
    body = l[l.find(']') + 1:]
    print(ts, body[:110])
