from PIL import Image

img = Image.open("assets/icons/dischargeiq_icon.png").convert("RGBA")
width, height = img.size

bg_color = img.getpixel((0, 0))

min_x = width
min_y = height
max_x = 0
max_y = 0

for x in range(width):
    for y in range(height):
        p = img.getpixel((x, y))
        dist = sum(abs(p[i] - bg_color[i]) for i in range(3))
        # Use a high tolerance for JPEG artifacts or slight gradients
        if dist > 80: 
            if x < min_x: min_x = x
            if y < min_y: min_y = y
            if x > max_x: max_x = x
            if y > max_y: max_y = y

if min_x > max_x:
    print("Could not find logo with tolerance 80")
else:
    print(f"Refined Logo Bounding Box (tol=80): {min_x}, {min_y}, {max_x}, {max_y}")
    print(f"Refined Logo Size: {max_x - min_x} x {max_y - min_y}")
