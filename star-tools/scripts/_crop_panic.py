from PIL import Image
p = "/mnt/c/ios26/screen-now-full.png"
im = Image.open(p)
print("size:", im.size)
W, H = im.size
bands = [
    ("band_a", 1750, 2050),
    ("band_b", 2050, 2350),
    ("band_c", 1400, 1750),
]
for name, y0, y1 in bands:
    crop = im.crop((20, y0, W - 20, y1))
    crop = crop.resize((crop.width * 2, crop.height * 2), Image.LANCZOS)
    out = f"/mnt/c/ios26/{name}.png"
    crop.save(out)
    print(name, "->", out, crop.size)
