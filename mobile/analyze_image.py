from PIL import Image

img = Image.open("assets/icons/dischargeiq_icon.png")
print("Mode:", img.mode)
print("Size:", img.size)

if img.mode == "RGBA":
    # Let's count transparent pixels
    pixels = img.load()
    transparent_count = 0
    total = img.size[0] * img.size[1]
    for x in range(img.size[0]):
        for y in range(img.size[1]):
            if pixels[x, y][3] == 0:
                transparent_count += 1
    print("Transparent pixels:", transparent_count, f"({transparent_count/total*100:.2f}%)")
else:
    print("No alpha channel")
