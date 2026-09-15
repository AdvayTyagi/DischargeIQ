from PIL import Image

img = Image.open("assets/icons/dischargeiq_icon.png").convert("RGBA")
width, height = img.size

# Sample corners to find the background color
corners = [
    img.getpixel((0, 0)),
    img.getpixel((width-1, 0)),
    img.getpixel((0, height-1)),
    img.getpixel((width-1, height-1))
]
print("Corner pixels:", corners)

# Let's see what color is at the center
print("Center pixel:", img.getpixel((width//2, height//2)))

# Find bounding box based on a tolerance from the top-left corner color
bg_color = corners[0]

min_x = width
min_y = height
max_x = 0
max_y = 0

for x in range(width):
    for y in range(height):
        p = img.getpixel((x, y))
        # Distance from background color
        dist = sum(abs(p[i] - bg_color[i]) for i in range(3))
        if dist > 30: # 30 is a safe tolerance
            if x < min_x: min_x = x
            if y < min_y: min_y = y
            if x > max_x: max_x = x
            if y > max_y: max_y = y

if min_x > max_x:
    print("Could not find logo")
else:
    print(f"Refined Logo Bounding Box: {min_x}, {min_y}, {max_x}, {max_y}")
    print(f"Refined Logo Size: {max_x - min_x} x {max_y - min_y}")
