import os
from PIL import Image, ImageDraw, ImageFont, ImageFilter

def create_gradient(width, height, start_color, end_color):
    base = Image.new('RGBA', (width, height), start_color)
    top = Image.new('RGBA', (width, height), end_color)
    mask = Image.new('L', (width, height))
    mask_data = []
    for y in range(height):
        for x in range(width):
            mask_data.append(int(255 * (y / height)))
    mask.putdata(mask_data)
    base.paste(top, (0, 0), mask)
    return base

def create_icon():
    size = 1024
    # Create assets directory if it doesn't exist
    if not os.path.exists('assets'):
        os.makedirs('assets')
    
    # Background - Dark blue/purple gradient
    icon = create_gradient(size, size, (5, 5, 20, 255), (20, 10, 40, 255))
    
    draw = ImageDraw.Draw(icon)
    
    # Add some "tech" grid lines
    line_color = (0, 255, 255, 30) # faint cyan
    for i in range(0, size, 100):
        draw.line([(i, 0), (i, size)], fill=line_color, width=2)
        draw.line([(0, i), (size, i)], fill=line_color, width=2)
        
    # Draw a glowing circle in the center
    center = size // 2
    radius = size // 3
    
    # Glow effect for the circle
    glow_layers = 10
    for i in range(glow_layers):
        alpha = int(100 * (1 - i/glow_layers))
        width_offset = i * 2
        draw.ellipse(
            [center - radius - width_offset, center - radius - width_offset, 
             center + radius + width_offset, center + radius + width_offset],
            outline=(0, 255, 255, alpha), width=2
        )

    # Draw the letter 'K'
    # Try to load a font, fallback to default
    try:
        font_path = "C:/Windows/Fonts/impact.ttf"
        context_font = ImageFont.truetype(font_path, 600)
    except:
        try:
           font_path = "C:/Windows/Fonts/arialbd.ttf"
           context_font = ImageFont.truetype(font_path, 600)
        except:
           context_font = ImageFont.load_default()

    text = "K"
    text_bbox = draw.textbbox((0, 0), text, font=context_font)
    text_width = text_bbox[2] - text_bbox[0]
    text_height = text_bbox[3] - text_bbox[1]
    
    text_x = center - text_width // 2
    text_y = center - text_height // 2 - 50 # Adjust vertical alignment

    # Draw text glow
    glow_color = (0, 255, 255) # Cyan
    for offset in range(15, 0, -1):
        draw.text((text_x + offset, text_y + offset), text, font=context_font, fill=(0, 0, 0, 50))
        draw.text((text_x - offset, text_y - offset), text, font=context_font, fill=(0, 0, 0, 50))
        draw.text((text_x, text_y), text, font=context_font, fill=glow_color)
        
    # Overlay a gradient mask on text to make it look metallic/tech
    # For simplicity, just solid white for now with cyan glow was good, let's stick to cyan.
    draw.text((text_x, text_y), text, font=context_font, fill=(255, 255, 255))

    # Save
    icon.save('assets/icon.png')
    print("Icon created at assets/icon.png")

if __name__ == "__main__":
    create_icon()
