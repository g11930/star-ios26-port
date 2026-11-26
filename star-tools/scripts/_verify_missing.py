import subprocess, re

def wsl(c):
    return subprocess.run(["wsl.exe","-d","Ubuntu-24.04","bash","-c",c],
                          capture_output=True, text=True).stdout

print("=== 1. kern_credential.c PAC guard (OURS vs dada intent) ===")
print(wsl("sed -n '3718,3740p' /root/star26/star-native/bsd/kern/kern_credential.c"))

print("=== 2. our miniamfi: does it register platform binaries / amfi table? ===")
print(wsl("grep -nE 'miniamfi|amfi_register|platform|CS_PLATFORM_BINARY|amfi_ops|register' /root/star26/star-native/libkern/amfi/miniamfi.c | head -20"))

print("=== 3. our minimac: sandbox check/lookup handlers ===")
print(wsl("grep -nE 'minimac|check-in|checkin|lookup|sandbox|MAC_POLICY|allowed|policy_check' /root/star26/star-native/bsd/kern/kern_minimac.c | head -30"))

print("=== 4. our ipc_policy: any enforcement defaults? ===")
print(wsl("grep -nE 'enforcement_mode|IPC_SEC_POLICY_MODE_ENFORCEMENT|ipc_sec_policy_array' /root/star26/star-native/osfmk/ipc/ipc_policy.c | head -20"))

print("=== 5. our ubc_subr: cs_blob entitlement guard? ===")
print(wsl("grep -nE 'csb_entitlements|crash cs_blob|VM_MIN_KERNEL_ADDRESS' /root/star26/star-native/bsd/kern/ubc_subr.c | head -10"))
