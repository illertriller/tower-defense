# Tower Defense — Development Roadmap
**Last updated:** 2026-01-30 (Phase 1 in progress)

---

## Phase 1: Core Game Loop ⏳
**Target:** Tonight (2026-01-30)
**Goal:** A complete, playable game with proper structure

| Task | Owner | Status |
|------|-------|--------|
| Start menu (backdrop, start/settings/exit) | EDI | ✅ Done |
| Start menu ember effects | EDI | ✅ Done |
| Level select screen (5 levels) | EDI | ✅ Done |
| Basic settings menu (placeholder) | EDI | ✅ Done (disabled) |
| Map/terrain rework (layered grass + dirt road) | EDI | ✅ Done (prev session) |
| 10 demon enemy types (sprites + static) | Leonard | ✅ 10/10 Done |
| 10 demon enemy types (walk animations) | Leonard | ⏳ 7/10 Done |
| 10 demon enemy types (stats + abilities) | EDI | ✅ Done |
| 5 levels with unique path layouts | EDI | ✅ Done |
| 10 waves per level, escalating difficulty | EDI | ✅ Done |
| Win screen (score summary) | EDI | ✅ Done |
| Lose screen (restart/main menu) | EDI | ✅ Done |
| Keyboard shortcuts (1-4, Space, ESC) | EDI | ✅ Done |
| Wave race condition fix | EDI | ✅ Done |
| Testing & bug fixes | EDI | 🔜 Next |

## Phase 2: Towers & Combat
**Target:** Next session(s)
**Goal:** Full tower roster with unique mechanics

| Task | Owner | Status |
|------|-------|--------|
| 10 new tower types (design + sprites) | Leonard | Pending |
| Tower mechanics (frost, flame, anti-air, etc.) | EDI | Pending |
| Flying enemy mechanic (wraith + anti-air) | EDI | Pending |
| Tower upgrade system (3 paths, 3 levels each) | EDI | Pending |
| Tower upgrade UI panel | EDI | Pending |
| Game economy balancing (costs, rewards) | EDI + Martin | Pending |

## Phase 3: UI Overhaul
**Target:** After Phase 2
**Goal:** WC3-inspired professional game UI

| Task | Owner | Status |
|------|-------|--------|
| Bottom panel UI (tower menu, info, controls) | EDI | Pending |
| WC3-style UI frame art | Leonard | Pending |
| In-game ESC menu (resume/settings/restart/quit) | EDI | Pending |
| Full settings menus (graphics/sound/keys) | EDI | Pending |
| Tower selection & info panel | EDI | Pending |
| Level select screen | EDI | ✅ Done (early) |

## Phase 4: Polish & Juice
**Target:** Final phase
**Goal:** Professional feel, replayability

| Task | Owner | Status |
|------|-------|--------|
| Sound effects (attacks, deaths, UI clicks) | EDI + Leonard | Pending |
| Particle effects (explosions, magic, frost) | EDI | Pending |
| Credits roll animation | EDI | Pending |
| Highscore persistence (save/load) | EDI | Pending |
| 5 unique map visual themes | Leonard | Pending |
| Enemy death animations | Leonard | Pending |
| Tower placement/build animations | EDI | Pending |
| Final balancing pass | EDI + Martin | Pending |

---

## Architecture Notes (Phase 1)
- **Start menu** → Level select → Gameplay → Win/Lose screens
- **LevelData class** (scripts/data/level_data.gd) — all level paths + wave definitions
- **GameManager autoload** — tracks level, wave, money, lives, scoring
- **Enemy system** — 10 types with colored placeholders as fallback for missing sprites
- **Path system** — curves set dynamically from LevelData, one generic level scene
- **Scoring** — lives * 100 + kills * 10 + time bonus (faster = more points)

## Future Ideas (Post-MVP, to discuss with Martin)
- Maul/maze mode (WC3 style — build your own path)
- Multiplayer
- Boss special abilities / phases
- Achievements
- Tower synergies (combo bonuses for adjacent towers)
- Endless/survival mode
- Mobile export
