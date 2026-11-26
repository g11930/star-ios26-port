import re,glob,os
fs=sorted(glob.glob(r"C:/ios26/now-*.bin"), key=os.path.getmtime)
p=fs[-1]; print("LOG:",p,os.path.getsize(p))
d=open(p,'rb').read().decode('utf-8','replace').replace('\x00','')
L=d.splitlines()
# 1. IOKit 服务注册/匹配
pats={
 'IOService registered/start':['IOService.*(start|register|probe)','IOServices:','IOServiceOpen'],
 'AnnibaleGPU':['AnnibaleGPU'],
 'MiniIOMobileFramebuffer':['MiniIOMobileFramebuffer','IOMobileFramebuffer'],
 'Display':['star_display','STARL','graphics console','scan-out','dcp','DCP','backlight'],
 'Touch/HID':['touch','Touch','IOHID','hid-','IOTouch','ft5','goodix','novatek','synaptics','IST','msg22'],
 'WiFi':['wifi','WiFi','WLAN','wlan','ath12k','wpa_supplicant','cfg80211','mac80211','BCM43','brcmfmac'],
 'Audio':['audio','Audio','sound','ASOC','adsp','ADSP','elm','CODEC','codec'],
 'Camera':['camera','Camera','isp','ISP','camss','sensor'],
 'Cellular/Modem':['modem','Modem','qmi','QMI','cellular','rmnet','AT+','voice'],
 'Bluetooth':['bluetooth','Bluetooth','hci','HCI','bt_','BlueTool'],
 'Battery/Power':['battery','Battery','charger','fuelgauge','powerd','IOPMPowerSource'],
 'NFC/UWB':['nfc','NFC','uwb','UWB'],
 'Fingerprint':['fingerprint','biometric','Bio','goodix','fpc'],
 'GPU/DRM':['msm_drm','drm','DRM','adreno','Adreno','AnnibaleGPU','gpu','GPU'],
 'USB':['xhci','dwc3','USB','usb'],
 'PCIe':['pcie','PCIe','PCI'],
}
for name,keys in pats.items():
    hits=[]
    for i,l in enumerate(L):
        for k in keys:
            if k in l: hits.append((i,l.strip())); break
    print(f"\n===== {name} ({len(hits)}) =====")
    for i,l in hits[:6]: print(f"  [{i}] {l[:200]}")
