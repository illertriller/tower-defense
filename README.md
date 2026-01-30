# 🏰 Tower Defense

A pixel art tower defense game built with Godot 4.

## Setup

1. Install [Godot 4.3+](https://godotengine.org/download)
2. Clone this repo: `git clone https://github.com/illertriller/tower-defense.git`
3. Open in Godot: Import project → select `project.godot`
4. Hit Play (F5)

## Project Structure

```
tower-defense/
├── assets/
│   ├── sprites/          ← Pixel art (towers, enemies, terrain)
│   ├── audio/            ← Sound effects & music
│   └── fonts/            ← Pixel fonts
├── scenes/
│   ├── main/             ← Main game scene
│   ├── towers/           ← Tower scenes
│   ├── enemies/          ← Enemy scenes
│   ├── projectiles/      ← Projectile scenes
│   ├── maps/             ← Level maps
│   └── ui/               ← UI scenes
├── scripts/
│   ├── managers/         ← Game, Wave, Build managers
│   ├── towers/           ← Tower & projectile logic
│   ├── enemies/          ← Enemy AI & types
│   └── ui/               ← UI scripts
└── autoload/             ← Singleton managers
```

## Tower Types

| Tower | Cost | Damage | Range | Fire Rate |
|-------|------|--------|-------|-----------|
| Arrow Tower | 50 | 10 | 150 | 1.0/s |
| Cannon Tower | 100 | 30 | 120 | 0.5/s |
| Magic Tower | 75 | 15 | 180 | 0.8/s |

## Enemy Types

| Enemy | Health | Speed | Reward |
|-------|--------|-------|--------|
| Basic | 50 | 80 | 10 |
| Fast | 30 | 150 | 15 |
| Tank | 200 | 40 | 30 |
| Boss | 500 | 50 | 100 |

## Credits

Built by Martin & EDI 🤖
Art: PixelLab AI + custom sprites
