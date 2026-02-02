# Tower Defense — Development Roadmap
**Last updated:** 2026-02-02
**Target release:** Feb 14, 2026 → itch.io

---

## ✅ Completed — Core Game (Jan 28–31)

Everything below is done and playable:

- **10 demon enemy types** — sprites, walk animations (7/10), stats, abilities
- **10 tower types** — unique mechanics (frost, flame, poison, holy, splash, anti-air, gold mine, etc.)
- **Tower upgrade system** — 3 paths, 3 levels each, universal tower script
- **5 levels** — unique path layouts, 10 waves each, escalating difficulty
- **Flying enemy mechanic** — wraith + anti-air tower
- **DoT system** — poison/burn damage over time
- **Splash damage system**
- **Full UI** — start menu, level select, in-game HUD (WC3-inspired), ESC menu, win/lose screens
- **Particle effects** — explosions, magic, frost, build animations
- **Credits roll**, highscore persistence, keyboard shortcuts
- **Terrain theme system** — per-level textures
- **GameManager autoload**, LevelData class, separated HUD scene

---

## 🔧 Week 1: Polish (Feb 3–9)

| # | Task | Owner | Status | Notes |
|---|------|-------|--------|-------|
| 1 | 🔊 Sound effects | EDI | 🔜 | Attacks, impacts, UI clicks, ambient, music |
| 2 | 💰 Economy balancing | EDI + Martin | 🔜 | Tower costs, enemy rewards, difficulty curve |
| 3 | ⚙️ Settings menus | EDI | 🔜 | Volume sliders, maybe graphics options |
| 4 | 🔓 Level lock logic | EDI | 🔜 | Currently commented out — re-enable + test |
| 5 | 🎨 Remaining walk animations | Leonard | 🔜 | 3/10 enemy types still need walk anims |
| 6 | 🖼️ WC3 UI frame art | Leonard | ⏳ | In progress |
| 7 | 💀 Enemy death animations | Leonard | ⏳ | In progress |

## 🚀 Week 2: Release Prep (Feb 10–14)

| # | Task | Owner | Status | Notes |
|---|------|-------|--------|-------|
| 8 | 🎨 Final visual polish pass | EDI + Leonard | 🔜 | |
| 9 | ⚖️ Final balancing pass | EDI + Martin | 🔜 | Playtesting |
| 10 | 🧪 Bug testing | EDI + Martin | 🔜 | Full playthrough all 5 levels |
| 11 | 📦 Godot export (HTML5 + Windows) | EDI | 🔜 | |
| 12 | 🌐 itch.io page setup | EDI + Martin | 🔜 | Screenshots, description, tags |
| 13 | 🎉 Release! | All | 🔜 | Target: Feb 14 |

---

## Architecture Notes
- **Start menu** → Level select → Gameplay → Win/Lose screens
- **LevelData class** (scripts/data/level_data.gd) — all level paths + wave definitions
- **GameManager autoload** — tracks level, wave, money, lives, scoring
- **Enemy system** — 10 types with colored placeholders as fallback for missing sprites
- **Path system** — curves set dynamically from LevelData, one generic level scene
- **Scoring** — lives × 100 + kills × 10 + time bonus (faster = more points)

## Future Ideas (Post-Release)
- Maul/maze mode (WC3 style — build your own path)
- Multiplayer
- Boss special abilities / phases
- Achievements
- Tower synergies (combo bonuses for adjacent towers)
- Endless/survival mode
- Mobile export
- More levels + enemy types
