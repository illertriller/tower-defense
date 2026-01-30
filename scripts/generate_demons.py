#!/usr/bin/env python3
"""Generate 10 demon enemy sprites for the tower defense game."""

import subprocess
import time
import os
from PIL import Image

ENEMIES_DIR = "/root/clawd/projects/tower-defense/assets/sprites/enemies"
STYLE_REF = "/tmp/demon_sprites/style_ref_128.png"  # 128x128 upscaled reference
TEMP_DIR = "/tmp/demon_sprites"
WORK_DIR = "/root/clawd"  # Must run mcporter from here for config

os.makedirs(TEMP_DIR, exist_ok=True)
os.makedirs(ENEMIES_DIR, exist_ok=True)

def mcp_call(call_str, timeout=120):
    """Execute an MCP call via mcporter from the clawd directory."""
    cmd = f"npx mcporter call '{call_str}'"
    print(f"  → {call_str[:120]}...", flush=True)
    try:
        result = subprocess.run(cmd, shell=True, capture_output=True, text=True, 
                                timeout=timeout, cwd=WORK_DIR)
        if result.returncode != 0:
            print(f"  ✗ Error: {result.stderr[:300]}", flush=True)
            return False
        if "Error:" in result.stdout:
            print(f"  ✗ API Error: {result.stdout[:300]}", flush=True)
            return False
        print(f"  ✓ OK", flush=True)
        return True
    except subprocess.TimeoutExpired:
        print(f"  ✗ Timeout", flush=True)
        return False

def generate_static(name, desc, neg=""):
    """Generate 128x128 sprite, scale to 64x64."""
    raw = f"{TEMP_DIR}/{name}_raw128.png"
    final = f"{ENEMIES_DIR}/{name}_enemy.png"
    
    neg_part = f', negative_description: "{neg}"' if neg else ""
    call = (
        f'pixellab.generate_image_bitforge('
        f'description: "pixel art {desc}, side view facing right, dark fantasy tower defense game sprite", '
        f'style_image_path: "{STYLE_REF}", '
        f'width: 128, height: 128, style_strength: 45, '
        f'no_background: true, '
        f'outline: "single color black outline", '
        f'shading: "highly detailed shading", '
        f'detail: "highly detailed"{neg_part}, '
        f'text_guidance_scale: 12, '
        f'save_to_file: "{raw}", show_image: false)'
    )
    
    if mcp_call(call) and os.path.exists(raw):
        img = Image.open(raw).convert("RGBA")
        scaled = img.resize((64, 64), Image.NEAREST)
        scaled.save(final)
        print(f"  → {final}", flush=True)
        return final
    return None

def generate_walk(name, desc, static_path):
    """Generate 4-frame walk animation sheet (256x64)."""
    sheet_path = f"{ENEMIES_DIR}/{name}_walk_sheet.png"
    anim_path = f"{TEMP_DIR}/{name}_anim.png"
    
    call = (
        f'pixellab.animate_with_text('
        f'description: "pixel art {desc}, walking cycle animation, side view facing right, dark fantasy tower defense", '
        f'action: "walking", '
        f'reference_image_path: "{static_path}", '
        f'width: 64, height: 64, '
        f'view: "side", direction: "right", n_frames: 4, '
        f'save_to_file: "{anim_path}", show_image: false)'
    )
    
    if mcp_call(call) and os.path.exists(anim_path):
        anim = Image.open(anim_path).convert("RGBA")
        w, h = anim.size
        print(f"  → Anim output: {w}x{h}", flush=True)
        
        if w == 256 and h == 64:
            anim.save(sheet_path)
        elif w >= 4 * h:
            # Horizontal strip
            frame_w = w // 4
            sheet = Image.new("RGBA", (256, 64), (0,0,0,0))
            for i in range(4):
                f = anim.crop((i*frame_w, 0, (i+1)*frame_w, h))
                f = f.resize((64, 64), Image.NEAREST)
                sheet.paste(f, (i*64, 0))
            sheet.save(sheet_path)
        elif h >= 4 * w:
            # Vertical strip
            frame_h = h // 4
            sheet = Image.new("RGBA", (256, 64), (0,0,0,0))
            for i in range(4):
                f = anim.crop((0, i*frame_h, w, (i+1)*frame_h))
                f = f.resize((64, 64), Image.NEAREST)
                sheet.paste(f, (i*64, 0))
            sheet.save(sheet_path)
        else:
            # Unknown format — try grid or single image
            sheet = Image.new("RGBA", (256, 64), (0,0,0,0))
            # Try 2x2 grid
            if w >= 2*h//2 and h >= 2*w//2:
                fw, fh = w//2, h//2
                for row in range(2):
                    for col in range(2):
                        i = row*2 + col
                        f = anim.crop((col*fw, row*fh, (col+1)*fw, (row+1)*fh))
                        f = f.resize((64, 64), Image.NEAREST)
                        sheet.paste(f, (i*64, 0))
            else:
                scaled = anim.resize((64, 64), Image.NEAREST)
                for i in range(4):
                    sheet.paste(scaled, (i*64, 0 if i%2==0 else -1))
            sheet.save(sheet_path)
        
        print(f"  → {sheet_path}", flush=True)
        return sheet_path
    
    # Fallback: bob animation from static
    print(f"  ⚠ Animation failed, creating bounce fallback", flush=True)
    return make_fallback(static_path, sheet_path)

def make_fallback(static_path, sheet_path):
    """Create a simple bounce-walk sheet from static sprite."""
    if not static_path or not os.path.exists(static_path):
        return None
    img = Image.open(static_path).convert("RGBA")
    sheet = Image.new("RGBA", (256, 64), (0,0,0,0))
    offsets = [0, -2, 0, 2]  # vertical bob
    for i, dy in enumerate(offsets):
        sheet.paste(img, (i*64, dy))
    sheet.save(sheet_path)
    print(f"  → Fallback: {sheet_path}", flush=True)
    return sheet_path

# ─── DEMON DEFINITIONS ───
DEMONS = [
    ("imp", 
     "small red and orange imp demon, hunched posture, tiny curved horns, pointed barbed tail, sharp claws, menacing grin, glowing yellow eyes",
     "large, tall, wings, armor, weapon, cute, friendly"),
    ("hellhound",
     "demonic hellhound wolf beast on four legs, dark black fur with glowing orange-red fire accents, burning red eyes, sharp fangs bared, muscular canine body, flames from paws",
     "humanoid, standing upright, cute, collar, friendly dog"),
    ("brute",
     "massive muscular red brute demon, huge curved ram horns, bronze armored chest plates, bulging arms, heavy fists, intimidating stance, dark red skin",
     "small, thin, wings, weapon, cute, friendly"),
    ("wraith",
     "ghostly floating wraith demon, translucent purple and blue ethereal body, tattered dark robes flowing, no legs visible, glowing white eyes, spectral wispy trail below",
     "legs, feet, solid body, armor, weapon, colorful, happy"),
    ("fire_elemental",
     "living fire elemental creature, humanoid shape made entirely of flames and lava, orange-yellow body with red-hot core, molten cracks, flickering flame hair and arms",
     "armor, clothing, solid skin, weapon, cold colors, blue, green"),
    ("shadow_stalker",
     "dark shadow stalker demon, sleek thin black shadowy body, two piercing bright green glowing eyes, stealthy crouched pose, wisps of dark smoke trailing, sharp clawed hands",
     "bulky, bright colors, armor, weapon, friendly, cute, red"),
    ("bone_golem",
     "massive bone golem construct, assembled from many large bones, large skull head with glowing green eye sockets, ribcage torso, bone arm clubs, towering skeletal construct",
     "flesh, skin, small, thin, cute, friendly, human"),
    ("succubus",
     "winged succubus demon, dark purple and crimson skin, bat-like wings spread, elegant demonic female figure, horns curving back, long tail, glowing purple eyes",
     "cute, friendly, modest, armor, bulky, male"),
    ("hell_knight",
     "armored hell knight demon warrior, heavy dark plate armor with red glowing runes, red and black color scheme, horned helmet, carrying dark sword, imposing stance",
     "small, thin, unarmored, cute, friendly, light colors"),
    ("demon_lord",
     "massive demon lord boss, huge imposing figure, enormous curved horns, dark crimson skin, large bat-like wings spread wide, glowing red eyes, royal demonic presence, crown of fire",
     "small, thin, cute, friendly, unimposing, no horns"),
]

def main():
    print("=" * 60, flush=True)
    print("DEMON SPRITE GENERATOR — 10 enemies", flush=True)
    print("=" * 60, flush=True)
    
    ok, fail = [], []
    
    for i, (name, desc, neg) in enumerate(DEMONS):
        print(f"\n[{i+1}/10] {name.upper()}", flush=True)
        
        # Static sprite
        print(f"  📌 Static...", flush=True)
        static = generate_static(name, desc, neg)
        if not static:
            fail.append(name)
            continue
        
        # Walk animation
        print(f"  🎬 Walk...", flush=True)
        walk = generate_walk(name, desc, static)
        
        ok.append(name)
        print(f"  ✅ {name} done", flush=True)
        time.sleep(0.5)
    
    print(f"\n{'='*60}", flush=True)
    print(f"✅ {len(ok)}/10: {', '.join(ok)}", flush=True)
    if fail:
        print(f"❌ Failed: {', '.join(fail)}", flush=True)
    
    print(f"\nFinal files:", flush=True)
    for f in sorted(os.listdir(ENEMIES_DIR)):
        fp = os.path.join(ENEMIES_DIR, f)
        if os.path.isfile(fp) and f.endswith('.png'):
            img = Image.open(fp)
            print(f"  {f} — {img.size[0]}x{img.size[1]} — {os.path.getsize(fp)}b", flush=True)

if __name__ == "__main__":
    main()
