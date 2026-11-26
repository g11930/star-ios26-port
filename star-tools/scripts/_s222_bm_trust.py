import plistlib
p = plistlib.load(open(r'D:/桌面/star26-deps/work/BuildManifest.plist', 'rb'))
ident = p['BuildIdentities'][0]
print('identity keys:', [k for k in ident if k != 'Manifest'])
m = ident['Manifest']
print('manifest entries:', len(m))
for key, info in m.items():
    low = (key + ' ' + str(info.get('Info', {}).get('Path', ''))).lower()
    if 'trust' in low or 'cryptex' in low or 'system' in low or 'static' in low:
        print(f'{key}\t{info.get("Info", {}).get("Path")}\t{info.get("Info", {}).get("Digest") and info["Info"]["Digest"][:12]}')
        print('   ', info.get('Info'))
