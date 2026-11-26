#!/usr/bin/env python3
# 只读：一锤定音——s208 vs s214 的激活状态判定差异
import re
FILES={"s208":"/mnt/c/ios26/s208-now.bin","s214":"/mnt/c/ios26/s214-late-051823.bin"}
PAT=["activated","Unactivated","activation state","setupActivationState","_setupActivationState",
     "SBLockdownManager","isActivated","ActivationState","Code=-8","Code=-536870201","UIK",
     "unlockUIFromSource","unlockedEnvironmentMode"]
def main():
    for label,path in FILES.items():
        print("="*68); print(label)
        lines=open(path,"rb").read().decode("utf-8","replace").splitlines()
        text="\n".join(lines)
        print("--- pattern counts ---")
        for k in PAT:
            c=text.count(k)
            if c: print("  %-28s %d"%(k,c))
        print("--- activation STATE lines (non-noise) ---")
        n=0
        for i,ln in enumerate(lines):
            low=ln.lower()
            if any(k.lower() in low for k in ("activated","activation state","setupactivationstate","code=-8","code=-536870201","uik","unlockedenvironmentmode","unlockuifromsource")):
                # skip file listing noise
                if "/annibale/LaunchDaemons" in ln or "plist" in ln: continue
                print("   [%d] %s"%(i+1,ln[:240])); n+=1
                if n>=30: break
if __name__=="__main__": main()
