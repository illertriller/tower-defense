#!/usr/bin/env python3
"""Retry walk animations for hell_hound, brute_demon, fire_elemental, bone_golem.
These got fallback bounces due to renamed references or rate limiting."""

import subprocess
import time
import os
from PIL import Image

ENEMIES_DIR = "/root/clawd/projects/tower-defense/assets/sprites/enemies"
TEMP_DIR = "/tmp/demon_sprites"
WORK_DIR = "/root/clawd"

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

def gen_walk(name, desc, static_path, sheet_path):
    base = f"{TEMP_DIR}/{name}_walk_retry"
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
            print(f"  → {sheet_path} ({os.path.getsize(sheet_path)}b)", flush=True)
            return True
    return False

RETRIES = [
    ("hell_hound",
     "demonic hellhound wolf beast on four legs, dark black fur with glowing orange-red fire accents, burning red eyes, sharp fangs bared, muscular canine body, flames from paws"),
    ("brute_demon",
     "massive muscular red brute demon, huge curved ram horns, bronze armored chest plates, bulging arms, heavy fists, intimidating stance, dark red skin"),
    ("fire_elemental",
     "living fire elemental creature, humanoid shape made entirely of flames and lava, orange-yellow body with red-hot core, molten cracks, flickering flame hair and arms"),
    ("bone_golem",
     "massive bone golem construct, assembled from many large bones, large skull head with glowing green eye sockets, ribcage torso, bone arm clubs, towering skeletal construct"),
]

def main():
    print("RETRY: 4 walk animations with 15s spacing", flush=True)
    
    for i, (name, desc) in enumerate(RETRIES):
        static = f"{ENEMIES_DIR}/{name}_enemy.png"
        sheet = f"{ENEMIES_DIR}/{name}_walk_sheet.png"
        
        if not os.path.exists(static):
            print(f"✗ {name}: no static sprite!", flush=True)
            continue
        
        print(f"\n[{i+1}/4] {name.upper()}", flush=True)
        
        if gen_walk(name, desc, static, sheet):
            print(f"  ✅ Done!", flush=True)
        else:
            print(f"  ❌ Still failed", flush=True)
        
        if i < len(RETRIES) - 1:
            print(f"  ⏳ Waiting 15s for rate limit...", flush=True)
            time.sleep(15)
    
    # Final check
    print(f"\nAll walk sheets:", flush=True)
    for f in sorted(os.listdir(ENEMIES_DIR)):
        if f.endswith('_walk_sheet.png'):
            fp = os.path.join(ENEMIES_DIR, f)
            sz = os.path.getsize(fp)
            real = "✅ real" if sz > 20000 else "⚠️ fallback"
            print(f"  {f:35s} {sz:>6d}b  {real}", flush=True)

if __name__ == "__main__":
    main()
