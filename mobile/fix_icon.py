from PIL import Image

def process_icon(input_path, output_path):
    img = Image.open(input_path).convert("RGBA")
    width, height = img.size
    
    # Bounding box from our analysis
    bbox = (472, 176, 938, 547)
    
    # We want to get the exact background color to fill the new image.
    # Let's take the color at (0,0) of the original image
    bg_color = img.getpixel((0, 0))
    
    # Crop the logo, including a tiny bit of margin to avoid hard edges
    margin = 5
    crop_box = (
        max(0, bbox[0] - margin),
        max(0, bbox[1] - margin),
        min(width, bbox[2] + margin),
        min(height, bbox[3] + margin)
    )
    
    logo = img.crop(crop_box)
    logo_w, logo_h = logo.size
    
    # Create 1024x1024 square with bg_color
    sq_size = 1024
    new_img = Image.new("RGBA", (sq_size, sq_size), bg_color)
    
    # User said: "Make the logo slightly larger only if necessary to make the composition look balanced"
    # Adaptive icons safe zone is a circle of diameter 66% of the icon size (1024 * 0.66 = 675)
    # The current logo size is 466x371. Let's scale it so its max dimension is about 650.
    target_size = 650
    scale = target_size / max(logo_w, logo_h)
    
    new_w = int(logo_w * scale)
    new_h = int(logo_h * scale)
    
    try:
        resample_filter = Image.Resampling.LANCZOS
    except AttributeError:
        resample_filter = Image.ANTIALIAS
        
    logo_resized = logo.resize((new_w, new_h), resample_filter)
    
    # Paste exactly in the center
    paste_x = (sq_size - new_w) // 2
    paste_y = (sq_size - new_h) // 2
    
    new_img.paste(logo_resized, (paste_x, paste_y))
    
    new_img.save(output_path)
    print(f"Saved centered icon to {output_path} with size {sq_size}x{sq_size}")
    print(f"Resized logo to {new_w}x{new_h} and pasted at {paste_x}, {paste_y}")

if __name__ == "__main__":
    process_icon("assets/icons/dischargeiq_icon.png", "assets/icons/dischargeiq_icon.png")
