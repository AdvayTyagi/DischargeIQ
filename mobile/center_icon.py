from PIL import Image

def process_icon(input_path, output_path):
    img = Image.open(input_path).convert("RGBA")
    
    pixels = img.load()
    width, height = img.size
    
    min_x = width
    min_y = height
    max_x = 0
    max_y = 0
    
    # Find bounding box of non-white and non-transparent pixels
    for x in range(width):
        for y in range(height):
            r, g, b, a = pixels[x, y]
            # Consider white as anything very close to white (e.g. > 240)
            if a > 10 and not (r > 240 and g > 240 and b > 240):
                if x < min_x: min_x = x
                if y < min_y: min_y = y
                if x > max_x: max_x = x
                if y > max_y: max_y = y
                
    if min_x > max_x or min_y > max_y:
        print("Could not find any non-white logo pixels.")
        return
        
    print(f"Logo bounding box: ({min_x}, {min_y}, {max_x}, {max_y})")
    
    # Crop the logo
    logo = img.crop((min_x, min_y, max_x + 1, max_y + 1))
    
    # Create a new square image with a white background
    # Standard max resolution for play store / launcher icons is 1024x1024
    sq_size = 1024
    new_img = Image.new("RGBA", (sq_size, sq_size), (255, 255, 255, 255))
    
    # Scale the logo. 
    # Adaptive icons usually show the inner 72/108 (~66%).
    # If the user says "Make the logo slightly larger only if necessary to make the composition look balanced"
    # Let's make the logo's max dimension 60% of the square. 1024 * 0.6 = 614
    logo_w, logo_h = logo.size
    print(f"Original logo size: {logo_w}x{logo_h}")
    
    # If the logo is wider than it is tall, its width becomes 614.
    scale = 614 / max(logo_w, logo_h)
    new_w = int(logo_w * scale)
    new_h = int(logo_h * scale)
    
    print(f"Scaled logo size: {new_w}x{new_h}")
    
    try:
        resample_filter = Image.Resampling.LANCZOS
    except AttributeError:
        resample_filter = Image.ANTIALIAS
        
    logo_resized = logo.resize((new_w, new_h), resample_filter)
    
    # Paste centered
    paste_x = (sq_size - new_w) // 2
    paste_y = (sq_size - new_h) // 2
    
    # We must paste using the logo itself as a mask to preserve alpha if any, 
    # but the image has no alpha. Let's just paste it directly.
    # Since the original image had no transparency, the cropped logo has a white background around the edges.
    # But wait, our bounding box might be tight, but it could have anti-aliased edges blending into white.
    # That's fine, pasting it onto a white background is perfect since it blends.
    new_img.paste(logo_resized, (paste_x, paste_y))
    
    new_img.save(output_path)
    print("Saved centered icon.")

if __name__ == "__main__":
    process_icon("assets/icons/dischargeiq_icon.png", "assets/icons/dischargeiq_icon_fixed.png")
