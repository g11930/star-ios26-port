from PIL import Image
im = Image.open("/mnt/c/ios26/screen-now-full.png")
W, H = im.size
# 覆盖 2350..2750，分三段，窄裁剪放大3倍让字更大
bands = [
    ("band_d", 2350, 2500),
    ("band_e", 2500, 2650),
    ("band_f", 2650, 2800),
    ("band_g", 2800, 2950),
]
for name, y0, y1 in bands:
    crop = im.crop((30, y0, W - 30, y1))
    crop = crop.resize((int(crop.width * 2.2), int(crop.height * 2.2)), Image.LANCZOS)
    out = f"/mnt/c/ios26/{name}.png"
    crop.save(out)
    print(name, "->", out, crop.size)
