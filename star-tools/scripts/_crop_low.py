from PIL import Image
im = Image.open("/mnt/c/ios26/screen-now-full.png")
# 下半红框 2650-3200 分三段，放大2.5倍
for name, y0, y1 in [("low1",2650,2830),("low2",2830,3010),("low3",3010,3190)]:
    crop = im.crop((30, y0, 1410, y1))
    crop = crop.resize((int(crop.width*2.5), int(crop.height*2.5)), Image.LANCZOS)
    crop.save(f"/mnt/c/ios26/{name}.png")
    print(name, crop.size)
