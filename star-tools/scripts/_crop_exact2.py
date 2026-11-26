from PIL import Image
im = Image.open("/mnt/c/ios26/screen-now-full.png")
crop = im.crop((30, 2055, 1410, 2110))
crop = crop.resize((int(crop.width * 4), int(crop.height * 4)), Image.LANCZOS)
crop.save("/mnt/c/ios26/band_exact2.png")
print("band_exact2", crop.size)
