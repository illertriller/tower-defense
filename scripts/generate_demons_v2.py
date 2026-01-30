#!/usr/bin/env python3
"""Generate all 10 demon sprites + walk animations. Fixed version with:
- direction: "east" (not "right")
- Individual frame files combined into sprite sheet
- Run from /root/clawd for mcporter config
"""

import subprocess
import time
import os
from PIL import Image

ENEMIES_DIR = "/root/clawd/projects/tower-defense/assets/sprites/enemies"
STYLE_REF = "/tmp/demon_sprites/style_ref_128.png"
TEMP_DIR = "/tmp/demon_sprites"
WORK_DIR = "/root/clawd"

os.makedirs(TEMP_DIR, exist_ok=True)
os.makedirs(ENEMIES_DIR, exist_ok=True)

def mcp(call_str, timeout=120):
    cmd = f"npx mcporter call '{call_str}'"
    print(f"  → {call_str[:100]}...", flush=True)
    try:
        r = subprocess.run(cmd, shell=True, capture_output=True, text=True, timeout=timeout, cwd=WORK_DIR)
        out = r.stdout + r.stderr
        if r.returncode != 0 or "Error" in out[:500]:
            print(f"  ✗ {out[:200]}", flush=True)
            return False
        print(f"  ✓ OK", flush=True)
        return True
    except subprocess.TimeoutExpired:
        print(f"  ✗ Timeout", flush=True)
        return False

def gen_static(name, desc, neg=""):
    raw = f"{TEMP_DIR}/{name}_raw128.png"
    final = f"{ENEMIES_DIR}/{name}_enemy.png"
    
    if os.path.exists(final):
        print(f"  → Already exists: {final}", flush=True)
        return final
    
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
    
    if mcp(call) and os.path.exists(raw):
        img = Image.open(raw).convert("RGBA")
        scaled = img.resize((64, 64), Image.NEAREST)
        scaled.save(final)
        print(f"  → {final}", flush=True)
        return final
    return None

def gen_walk(name, desc, static_path):
    sheet_path = f"{ENEMIES_DIR}/{name}_walk_sheet.png"
    base = f"{TEMP_DIR}/{name}_walk"
    
    call = (
        f'pixellab.animate_with_text('
        f'description: "pixel art {desc}, walking cycle, side view, dark fantasy tower defense", '
        f'action: "walking", '
        f'reference_image_path: "{static_path}", '
        f'width: 64, height: 64, '
        f'view: "side", direction: "east", n_frames: 4, '
        f'save_to_file: "{base}.png", show_image: false)'
    )
    
    if mcp(call):
        # Check for individual frame files
        frames = []
        for i in range(4):
            fpath = f"{base}_frame{i}.png"
            if os.path.exists(fpath):
                frames.append(Image.open(fpath).convert("RGBA"))
        
        if len(frames) == 4:
            sheet = Image.new("RGBA", (256, 64), (0,0,0,0))
            for i, f in enumerate(frames):
                if f.size != (64, 64):
                    f = f.resize((64, 64), Image.NEAREST)
                sheet.paste(f, (i*64, 0))
            sheet.save(sheet_path)
            print(f"  → {sheet_path} (4 real frames)", flush=True)
            return sheet_path
        
        # Check for single combined file
        if os.path.exists(f"{base}.png"):
            img = Image.open(f"{base}.png").convert("RGBA")
            w, h = img.size
            if w >= 4*h:
                fw = w // 4
                sheet = Image.new("RGBA", (256, 64), (0,0,0,0))
                for i in range(4):
                    f = img.crop((i*fw, 0, (i+1)*fw, h)).resize((64,64), Image.NEAREST)
                    sheet.paste(f, (i*64, 0))
                sheet.save(sheet_path)
                print(f"  → {sheet_path} (strip)", flush=True)
                return sheet_path
    
    # Fallback: bounce from static
    print(f"  ⚠ Using bounce fallback", flush=True)
    return make_fallback(static_path, sheet_path)

def make_fallback(static_path, sheet_path):
    if not static_path or not os.path.exists(static_path):
        return None
    img = Image.open(static_path).convert("RGBA")
    sheet = Image.new("RGBA", (256, 64), (0,0,0,0))
    for i, dy in enumerate([0, -2, 0, 2]):
        sheet.paste(img, (i*64, dy))
    sheet.save(sheet_path)
    return sheet_path

# ─── ALL 10 DEMONS ───
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
    print("DEMON SPRITES — Phase 1", flush=True)
    print("=" * 60, flush=True)
    
    # Phase 1: Generate all static sprites
    print("\n─── PHASE 1: Static Sprites ───", flush=True)
    statics = {}
    for i, (name, desc, neg) in enumerate(DEMONS):
        print(f"\n[{i+1}/10] {name.upper()} static", flush=True)
        path = gen_static(name, desc, neg)
        if path:
            statics[name] = path
        else:
            print(f"  ❌ FAILED", flush=True)
        time.sleep(0.5)
    
    print(f"\n✅ Statics: {len(statics)}/10", flush=True)
    
    # Phase 2: Generate all walk animations
    print("\n─── PHASE 2: Walk Animations ───", flush=True)
    walks = {}
    for i, (name, desc, neg) in enumerate(DEMONS):
        if name not in statics:
            print(f"\n[{i+1}/10] {name.upper()} — skipped (no static)", flush=True)
            continue
        print(f"\n[{i+1}/10] {name.upper()} walk", flush=True)
        path = gen_walk(name, desc, statics[name])
        if path:
            walks[name] = path
        time.sleep(0.5)
    
    print(f"\n✅ Walks: {len(walks)}/10", flush=True)
    
    # Summary
    print(f"\n{'='*60}", flush=True)
    print("FINAL FILES:", flush=True)
    for f in sorted(os.listdir(ENEMIES_DIR)):
        fp = os.path.join(ENEMIES_DIR, f)
        if os.path.isfile(fp) and f.endswith('.png'):
            img = Image.open(fp)
            print(f"  {f:30s} {img.size[0]:3d}x{img.size[1]:3d}  {os.path.getsize(fp):>6d}b", flush=True)

if __name__ == "__main__":
    main()
