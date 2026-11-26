#!/usr/bin/env python3
# 只读：对比 s208(能解锁) vs s214(不解锁) 的激活/解锁链路关键日志
import re

FILES = {
    "s208": "/mnt/c/ios26/s208-now.bin",
    "s214": "/mnt/c/ios26/s214-late-051823.bin",
}
KEYS = ["mobileactivationd", "AppleKeyStore", "UIK", "MobileActivation", "activation",
        "Setup", "setup", "lockdown", "Lockdown", "unlock", "Unlock", "SpringBoard[33",
        "SystemShell", "persona", "UserInteractive", "backboardd", "(data)",
        "com.apple.lock", "CoverSheet", "SBLock"]

def main():
    for label, path in FILES.items():
        print("=" * 70)
        print(label, path)
        lines = open(path, "rb").read().decode("utf-8","replace").splitlines()
        # counts
        text="\n".join(lines)
        print("--- key counts ---")
        for k in KEYS:
            c=text.count(k)
            if c: print("  %-24s %d"%(k,c))
        # mobileactivation / keystore / UIK lines context
        print("--- activation/keystore lines (first 25) ---")
        n=0
        for i,ln in enumerate(lines):
            if any(k in ln for k in ("mobileactivationd","AppleKeyStore","UIK","MobileActivation","com.apple.MobileActivation")):
                print("   [%d] %s"%(i+1,ln[:230])); n+=1
                if n>=25: break
        # SpringBoard[33 last lines
        print("--- SpringBoard lines (last 12) ---")
        sb=[ln for ln in lines if "SpringBoard[" in ln]
        for ln in sb[-12:]: print("   ",ln[:210])

if __name__=="__main__": main()
