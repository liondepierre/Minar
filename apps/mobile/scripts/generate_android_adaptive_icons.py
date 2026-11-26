import os
from PIL import Image, ImageDraw

def generate_icons(src_icon_path, res_dir):
    print("Generating Android Adaptive & Legacy Icons...")
    im = Image.open(src_icon_path)
    w, h = im.size

    # 1. Cleanly extract gold emblem with antialiasing
    fg = Image.new('RGBA', (w, h), (0, 0, 0, 0))
    for y in range(h):
        for x in range(w):
            r, g, b, a = im.getpixel((x, y))
            if a > 10 and r > 70 and g > 60 and r > b + 20:
                diff = r - b
                alpha = int(min(255, max(0, (r - 70) * 3)))
                fg.putpixel((x, y), (r, g, b, min(a, alpha)))

    bbox = fg.getbbox()
    emblem = fg.crop(bbox)

    # 2. Build 1080x1080 master foreground (emblem in central 66% safe zone)
    MASTER_SIZE = 1080
    fg_master = Image.new('RGBA', (MASTER_SIZE, MASTER_SIZE), (0, 0, 0, 0))
    max_target = 660
    scale = min(max_target / emblem.width, max_target / emblem.height)
    new_w = int(emblem.width * scale)
    new_h = int(emblem.height * scale)
    scaled_emblem = emblem.resize((new_w, new_h), Image.Resampling.LANCZOS)
    off_x = (MASTER_SIZE - new_w) // 2
    off_y = (MASTER_SIZE - new_h) // 2
    fg_master.paste(scaled_emblem, (off_x, off_y), scaled_emblem)

    # 3. Build 1080x1080 master background (dark midnight gradient matching app)
    bg_master = Image.new('RGBA', (MASTER_SIZE, MASTER_SIZE))
    draw = ImageDraw.Draw(bg_master)
    for y in range(MASTER_SIZE):
        t = y / (MASTER_SIZE - 1.0)
        # Gradient: Top #1B2640 -> Bottom #0A1020
        r = int(27 * (1 - t) + 10 * t)
        g = int(38 * (1 - t) + 16 * t)
        b = int(64 * (1 - t) + 32 * t)
        draw.line([(0, y), (MASTER_SIZE - 1, y)], fill=(r, g, b, 255))

    # Master composite (background + foreground) for legacy icons
    composite_master = Image.alpha_composite(bg_master, fg_master)

    # Master round composite
    circle_mask = Image.new('L', (MASTER_SIZE, MASTER_SIZE), 0)
    c_draw = ImageDraw.Draw(circle_mask)
    c_draw.ellipse([(140, 140), (MASTER_SIZE - 140, MASTER_SIZE - 140)], fill=255)
    round_master = Image.new('RGBA', (MASTER_SIZE, MASTER_SIZE), (0, 0, 0, 0))
    round_master.paste(composite_master, (0, 0), circle_mask)
    round_master = round_master.crop((140, 140, MASTER_SIZE - 140, MASTER_SIZE - 140))

    # Density specifications
    # (density_name, foreground_size, legacy_size)
    densities = [
        ('mipmap-mdpi', 108, 48),
        ('mipmap-hdpi', 162, 72),
        ('mipmap-xhdpi', 216, 96),
        ('mipmap-xxhdpi', 324, 144),
        ('mipmap-xxxhdpi', 432, 192),
    ]

    for dir_name, fg_size, leg_size in densities:
        target_dir = os.path.join(res_dir, dir_name)
        os.makedirs(target_dir, exist_ok=True)

        # 1. Foreground for Adaptive Icon
        fg_out = fg_master.resize((fg_size, fg_size), Image.Resampling.LANCZOS)
        fg_out.save(os.path.join(target_dir, 'ic_launcher_foreground.png'))

        # 2. Legacy square icon (full bleed dark midnight background, NO white circle!)
        leg_out = composite_master.resize((leg_size, leg_size), Image.Resampling.LANCZOS)
        leg_out.save(os.path.join(target_dir, 'ic_launcher.png'))

        # 3. Legacy round icon (circular clipped dark midnight icon)
        round_out = round_master.resize((leg_size, leg_size), Image.Resampling.LANCZOS)
        round_out.save(os.path.join(target_dir, 'ic_launcher_round.png'))

        print(f"Generated {dir_name}: fg={fg_size}x{fg_size}, legacy={leg_size}x{leg_size}")

if __name__ == '__main__':
    src = '/Users/yma/dev/minar_mobile/assets/icon/app_icon.png'
    res = '/Users/yma/dev/minar_mobile/android/app/src/main/res'
    generate_icons(src, res)
