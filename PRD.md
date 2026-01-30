# Tower Defense — Product Requirements Document
**Date:** 2026-01-30
**Client:** Martin
**Lead Dev:** EDI
**Design:** Leonard of Quirm

---

## 1. Start Menu
- **Backdrop:** Full-screen pixel art backdrop image (fantasy/medieval themed)
- **Buttons** (centered, slightly right of center):
  - **Start Game** → launches into level select or first level
  - **Settings** → sub-menu with:
    - Graphics settings
    - Sound settings
    - In-game options
    - Key shortcut customisation
  - **Exit Game** → quits application

## 2. Levels & Waves
- **5 distinct levels**, each with unique map layout
- **10 waves per level**
- **Progressive difficulty** — Level 1 is easy intro, Level 5 is brutal
- Each level should have different path layouts and visual themes
- Enemies get tougher and more varied as levels progress

## 3. Enemies — 10 New Types (Demon/Hell Theme)
All enemies are **demons from hell**, NOT animals. High detail, 64x64 sprites with walk animations.

Suggested roster (varied abilities):
1. **Imp** — basic weak demon (low HP, medium speed, fodder)
2. **Hell Hound** — fast runner (low HP, very fast)
3. **Brute Demon** — tank (high HP, slow, armored)
4. **Wraith** — flying/air enemy (medium HP, medium speed, ignores ground obstacles)
5. **Fire Elemental** — medium enemy with fire aura (damages nearby towers?)
6. **Shadow Stalker** — stealth enemy (becomes invisible periodically)
7. **Bone Golem** — very tanky (very high HP, very slow)
8. **Succubus** — healer (medium HP, heals nearby enemies)
9. **Hell Knight** — elite (high HP, medium speed, armored)
10. **Demon Lord** — boss (massive HP, slow, spawns minions)

Each needs:
- Unique sprite (64x64, demon themed)
- 4-frame walk animation
- Sprite sheet (256x64)
- Specific stats (HP, speed, reward, abilities)

## 4. Towers — 10 New Types (+ Existing 4)
Existing: Arrow (crossbow), Cannon, Magic, Tesla

New towers to add:
1. **Frost Tower** — low damage, slows enemies significantly
2. **Flame Tower** — AoE fire damage over time
3. **Anti-Air Tower** — targets flying enemies specifically
4. **Sniper Tower** — very long range, high single-target damage, slow fire rate
5. **Poison Tower** — applies poison DoT (damage over time)
6. **Bomb Tower** — splash damage in area
7. **Holy Tower** — bonus damage to demon/undead types
8. **Barracks Tower** — spawns melee units that block enemies
9. **Gold Mine** — generates extra gold per wave (utility)
10. **Storm Tower** — chain lightning upgrade of Tesla concept

Each needs:
- Unique sprite (128→64, themed to ability)
- Balanced cost (not all 1g — proper economy)
- Unique attack mechanics
- Integration with upgrade system

## 5. Tower Upgrade System
- **Per-tower upgrade interface** — click a placed tower to open upgrade panel
- **3 upgrade paths per tower**, e.g.:
  - Cannon: Splash radius / Damage / Fire rate
  - Tesla: Max targets / Damage / Range
  - Frost: Slow strength / Slow duration / Range
- **3 upgrade levels** per path
- Costs increase per level
- Visual indication of upgrade level on tower sprite (subtle glow or marker)

## 6. Advanced UI (WC3-Inspired)
- **Bottom panel** with:
  - Tower building menu (grid of tower icons with costs)
  - Selected tower info (stats, upgrade buttons)
  - Game controls (pause, settings, main menu, restart)
- **Top bar:** Gold, lives, wave counter, level name
- **In-game menu** (ESC): Resume, Settings, Restart Level, Main Menu
- Clean, readable, fantasy-themed UI frames

## 7. Map/Terrain Rework
- **Grass field** as continuous background layer (NOT grid-tied squares/circles)
- **Dirt road** layered on top, following path but looking natural
- **Building grid** is a separate layer — subtle, only visible when placing towers
- **5 unique map layouts** for the 5 levels
- Each map has different path patterns and possibly different terrain themes
- No "choppy bushes" — smooth, natural-looking pixel art terrain

## 8. Win/Lose Screens
**Win Screen (beat all waves):**
- Victory message / animation
- Credits roll
- Highscore log:
  - Lives remaining
  - Enemies killed
  - Total gold collected
  - Time taken
  - Final score

**Lose Screen (lives reach 0):**
- "You Lose!" message
- Options: Restart Level / Main Menu

---

## Priority Phases

### Phase 1 — Core Game Loop (Tonight)
- [ ] Start menu (backdrop + buttons + basic settings)
- [ ] Map/terrain rework (proper grass + dirt road layering)
- [ ] 10 demon enemy types (sprites + stats + animations) — **Leonard**
- [ ] Win/Lose screens with score summary
- [ ] 5 levels with 10 waves each

### Phase 2 — Towers & Combat
- [ ] 10 new tower types (sprites + mechanics) — **Leonard** for art
- [ ] Proper tower costs and game economy balance
- [ ] Tower upgrade system + UI
- [ ] Anti-air mechanics (flying enemies + anti-air tower)

### Phase 3 — UI Polish
- [ ] WC3-style bottom panel UI
- [ ] In-game menu (ESC)
- [ ] Settings menus (graphics, sound, keys)
- [ ] Tower selection/info panel

### Phase 4 — Polish & Juice
- [ ] Sound effects
- [ ] Particle effects
- [ ] Credits roll
- [ ] Highscore persistence (save to file)
- [ ] 5 unique map layouts
