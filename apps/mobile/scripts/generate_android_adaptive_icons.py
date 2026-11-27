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

    # 2. Build 1080x1080 master foreground (emblem at natural proportion, 54.6% of 720 safe zone)
    MASTER_SIZE = 1080
    TARGET_MASK_SIZE = 720 # 72dp safe zone out of 108dp canvas
    # In original icon, emblem was 899x824 inside 1647 squircle
    target_w = int(TARGET_MASK_SIZE * (emblem.width / 1647.0))
    target_h = int(TARGET_MASK_SIZE * (emblem.height / 1647.0))
    scaled_emblem = emblem.resize((target_w, target_h), Image.Resampling.LANCZOS)

    fg_master = Image.new('RGBA', (MASTER_SIZE, MASTER_SIZE), (0, 0, 0, 0))
    off_x = (MASTER_SIZE - target_w) // 2
    off_y = (MASTER_SIZE - target_h) // 2
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

    # Master composite (background + foreground)
    composite_master = Image.alpha_composite(bg_master, fg_master)

    # Master square legacy icon (crop to safe zone 720x720, full bleed dark gradient, NO white circle!)
    margin = (MASTER_SIZE - TARGET_MASK_SIZE) // 2
    legacy_square_master = composite_master.crop((margin, margin, MASTER_SIZE - margin, MASTER_SIZE - margin))

    # Master round composite (720x720 circular clipped)
    circle_mask = Image.new('L', (TARGET_MASK_SIZE, TARGET_MASK_SIZE), 0)
    c_draw = ImageDraw.Draw(circle_mask)
    c_draw.ellipse([(0, 0), (TARGET_MASK_SIZE, TARGET_MASK_SIZE)], fill=255)
    round_master = Image.new('RGBA', (TARGET_MASK_SIZE, TARGET_MASK_SIZE), (0, 0, 0, 0))
    round_master.paste(legacy_square_master, (0, 0), circle_mask)

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
        leg_out = legacy_square_master.resize((leg_size, leg_size), Image.Resampling.LANCZOS)
        leg_out.save(os.path.join(target_dir, 'ic_launcher.png'))

        # 3. Legacy round icon (circular clipped dark midnight icon)
        round_out = round_master.resize((leg_size, leg_size), Image.Resampling.LANCZOS)
        round_out.save(os.path.join(target_dir, 'ic_launcher_round.png'))

        print(f"Generated {dir_name}: fg={fg_size}x{fg_size}, legacy={leg_size}x{leg_size}")

if __name__ == '__main__':
    src = '/Users/yma/dev/minar_mobile/assets/icon/app_icon.png'
    res = '/Users/yma/dev/minar_mobile/android/app/src/main/res'
    generate_icons(src, res)
