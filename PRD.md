# PRD — Tower Defense: Release Polish Sprint
**Created:** 2026-02-02
**Target release:** Feb 14, 2026 → itch.io
**Owner:** EDI + Martin

---

## 1. 🔊 Sound Effects — Attacks, Impacts, UI, Ambient
**Status:** 🟡 In progress (audio files gathered, integration underway)
**Priority:** High — biggest impact on game feel

### What we have
44 audio files in `assets/audio/` organised as:
- `ui/` — button clicks, hover, tower place/upgrade/sell, wave start, victory, defeat, menu open/close
- `combat/` — arrow fire, frost/fire/poison/holy attacks, explosions, enemy hits (4 variants), enemy deaths (4 variants), gold pickup (3 variants), spell effects
- `music/` — menu theme, 2 battle loops, victory theme

### What needs doing

#### 1.1 AudioManager Autoload (NEW)
Create `autoload/audio_manager.gd` — singleton handling all game audio:
- **SFX pool:** 8-12 `AudioStreamPlayer` nodes for overlapping sound effects
- **Music players:** 2 `AudioStreamPlayer` nodes for crossfading between tracks
- **Preloaded sounds:** Dictionary mapping sound names → `AudioStream` resources
- **Variant support:** Where we have multiple versions (e.g. `button_click`, `button_click_2`, `button_click_3`), pick randomly
- **Volume controls:** `master_volume`, `sfx_volume`, `music_volume` (0.0–1.0), saved to disk
- **Key methods:**
  - `play_sfx(name: String, volume_db: float = 0.0)`
  - `play_music(name: String, fade_in: float = 1.0)`
  - `stop_music(fade_out: float = 1.0)`
  - `set_sfx_volume(vol: float)` / `set_music_volume(vol: float)`
- Register in `project.godot` autoloads

#### 1.2 Combat Sound Integration
Wire into existing scripts — **minimal, surgical edits:**

| Sound | Trigger | File to edit |
|-------|---------|-------------|
| `arrow_fire` / `arrow_fire_2` | Tower fires projectile (arrow type) | `scripts/towers/tower.gd` |
| `frost_attack` | Frost tower fires | `scripts/towers/tower.gd` |
| `fire_attack` | Flame tower ticks | `scripts/towers/tower.gd` |
| `poison_attack` | Poison tower fires | `scripts/towers/tower.gd` |
| `holy_attack` | Holy tower fires | `scripts/towers/tower.gd` |
| `spell_00`–`spell_03` | Magic/tesla/storm tower fires | `scripts/towers/tower.gd` |
| `explosion_impact` | Splash projectile hits | `scripts/towers/projectile.gd` |
| `enemy_hit` variants | Enemy takes damage | `scripts/enemies/enemy.gd` |
| `enemy_death` variants | Enemy dies | `scripts/enemies/enemy.gd` |
| `gold_pickup` variants | Gold awarded on kill | `scripts/enemies/enemy.gd` or `game_manager.gd` |

**Tower → sound mapping:**
```
arrow_tower    → arrow_fire
cannon_tower   → arrow_fire (cannon variant if available, else arrow)
magic_tower    → spell_00, spell_01 (random)
tesla_tower    → spell_02 (electric feel)
frost_tower    → frost_attack
flame_tower    → fire_attack
antiair_tower  → arrow_fire_2
sniper_tower   → arrow_fire (sharp crack)
poison_tower   → poison_attack
bomb_tower     → explosion_impact (on fire, not just hit)
holy_tower     → holy_attack
storm_tower    → spell_03
barracks_tower → (silent — passive)
gold_mine      → gold_pickup (on wave income)
```

#### 1.3 UI Sound Integration

| Sound | Trigger | File to edit |
|-------|---------|-------------|
| `button_click` variants | Any button press | All UI scripts (start_menu, level_select, game_hud, settings_menu, win/lose) |
| `button_hover` variants | Mouse enters button | Same — connect `mouse_entered` signal |
| `tower_place` | Tower built on grid | `scripts/managers/build_manager.gd` |
| `tower_upgrade` | Tower upgraded | `scripts/managers/build_manager.gd` or `game_hud.gd` |
| `tower_sell` | Tower sold | `scripts/managers/build_manager.gd` |
| `wave_start` | New wave begins | `scripts/managers/wave_manager.gd` |
| `error` | Can't afford / invalid placement | `scripts/managers/build_manager.gd` |

#### 1.4 Music Integration

| Track | When | Where |
|-------|------|-------|
| `menu_theme` | Start menu, level select | `scenes/ui/start_menu.gd` — play on `_ready()` |
| `battle_loop` | During gameplay | `scenes/main/main.gd` — play when level starts |
| `battle_loop_alt` | Alternate randomly or on certain levels | Same |
| `victory_theme` | Level complete | `scenes/ui/win_screen.gd` — stop battle, play victory |
| `victory_fanfare` | Quick sting on win | `scenes/ui/win_screen.gd` — play before theme |
| `defeat` | Game over | `scenes/ui/lose_screen.gd` — stop battle, play defeat |

**Music should loop.** Menu music persists across start_menu ↔ level_select. Stops when gameplay starts.

### Acceptance Criteria
- [ ] Every tower type plays an appropriate attack sound
- [ ] Enemy hit/death sounds play with random variant selection
- [ ] All UI buttons click and hover
- [ ] Music transitions smoothly between menu → gameplay → win/lose
- [ ] No audio clipping from overlapping sounds (SFX pool manages this)
- [ ] Volume levels feel balanced (combat doesn't drown out music)

---

## 2. 💰 Economy Balancing — Tower Costs, Enemy Rewards, Difficulty Curve
**Status:** 🔜 Not started
**Priority:** High — directly affects fun factor

### Current State
- **Starting gold:** 100 + 25 per level (L1=100, L2=125, L3=150, L4=175, L5=200)
- **Lives:** 20 (all levels)
- **Wave completion bonus:** 25 + (wave × 5) gold
- **Towers cost:** 50–200 gold (see tower_data in game_manager.gd)
- **No enemy reward data visible in game_manager** — need to check enemy.gd

### What Needs Balancing

#### 2.1 Economy Flow Analysis
- Play through Level 1 mentally / mathematically:
  - Wave 1: 5 imps. Reward per imp? Starting gold 100. Cheapest tower 50 (arrow).
  - Can player afford 2 towers before first wave? (Yes, exactly)
  - Does gold income allow building up through 10 waves?
- **Key question:** Is there a "sweet spot" where the player feels stretched but not stuck?

#### 2.2 Specific Balance Points

| Parameter | Current | Concern |
|-----------|---------|---------|
| Starting gold (L1) | 100 | Can only buy 2 arrow towers or 1 cannon — feels tight? |
| Arrow tower cost | 50 | Seems right for basic tower |
| Cannon tower cost | 100 | Fair for splash damage |
| Gold mine cost | 200 | Very expensive — does it pay back fast enough? (30g/wave × ~8 remaining waves = 240g if bought wave 2) |
| Wave bonus | 25 + wave×5 | W1=30, W5=50, W10=75 — decent ramp |
| Sniper tower cost | 150 | High but 80 damage + 300 range is powerful |
| Upgrade costs | 25–300 | Wide range — are early upgrades worth it vs new tower? |
| Level 5 starting gold | 200 | Enough for the difficulty spike? |

#### 2.3 Enemy Rewards
Need to verify/set kill rewards per enemy type:

| Enemy | Suggested Reward | Reasoning |
|-------|-----------------|-----------|
| Imp | 5g | Trash mob, many spawned |
| Hell Hound | 8g | Fast but fragile |
| Shadow Stalker | 10g | Sneaky, medium threat |
| Fire Elemental | 12g | Damage resistance theme |
| Brute Demon | 15g | Tanky, slow |
| Succubus | 15g | Special abilities |
| Wraith | 12g | Flying, hard to hit |
| Bone Golem | 20g | Very tanky |
| Hell Knight | 25g | Elite |
| Demon Lord | 50g | Boss-tier |

#### 2.4 Difficulty Curve
- **Level 1:** Tutorial-easy. Player should win on first try if they place towers sensibly
- **Level 2:** Introduces variety. Some enemies get through if placement is bad
- **Level 3:** Requires strategy. Wrong tower composition = loss
- **Level 4:** Hard. Needs good upgrades and tower synergy
- **Level 5:** Brutal. Wave 10 ("HELL UNLEASHED") should feel genuinely overwhelming

#### 2.5 Process
1. Document current enemy stats (HP, speed, reward) from `enemy.gd`
2. Spreadsheet: gold income vs gold needed per level
3. Adjust values in `game_manager.gd` (tower costs, starting gold, wave bonuses)
4. Adjust values in `enemy.gd` (kill rewards, HP scaling)
5. Playtest mentally or build a balance simulator script
6. Martin playtests and gives feedback

### Acceptance Criteria
- [ ] Level 1 is completable by a new player without prior knowledge
- [ ] Level 5 is genuinely difficult — requires strategy and smart upgrades
- [ ] Gold mine is a viable investment (pays back in 6-7 waves)
- [ ] Every tower type is worth building in at least some situation
- [ ] No tower is so dominant it makes others pointless
- [ ] Upgrades feel meaningful — not just "+2 damage for 100 gold"

---

## 3. ⚙️ Settings Menus — Volume Sliders + Graphics Options
**Status:** 🔜 Not started
**Priority:** Medium — needed for release, depends on AudioManager

### Current State
`settings_menu.gd` currently has:
- ✅ Resolution selector (dropdown)
- ✅ Map size selector (dropdown)
- ✅ Fullscreen toggle
- ✅ Camera edge pan toggle
- ✅ Minimap toggle
- ❌ No volume controls
- ❌ No audio settings at all

### What Needs Adding

#### 3.1 Audio Settings
Add to the existing settings panel:

| Control | Type | Range | Default |
|---------|------|-------|---------|
| Master Volume | HSlider | 0–100 | 80 |
| Music Volume | HSlider | 0–100 | 60 |
| SFX Volume | HSlider | 0–100 | 80 |
| Mute All | CheckButton | on/off | off |

**Implementation:**
- Add `HSlider` nodes to `settings_menu.tscn` in new "Audio" section
- Connect to `AudioManager.set_master_volume()`, `set_music_volume()`, `set_sfx_volume()`
- Save/load via `SaveManager` (extend save_data.json with audio prefs)
- Play a sample click sound when adjusting SFX slider (feedback)

#### 3.2 Settings Persistence
- Extend `SaveManager` to save/load settings (volume, fullscreen, etc.)
- Load settings on game start (before anything plays)
- The existing `Settings` autoload might handle this — check and extend

#### 3.3 Settings Access Points
Settings menu should be reachable from:
- ✅ Start menu (already has button, currently opens existing settings)
- ✅ In-game ESC menu (already has settings button)
- Both should open the **same** settings panel with all options

### Acceptance Criteria
- [ ] Player can adjust master/music/SFX volume independently
- [ ] Volume settings persist between sessions
- [ ] Settings accessible from both main menu and in-game
- [ ] Mute toggle works
- [ ] Slider changes apply immediately (not just on save)

---

## 4. 🔓 Level Lock Logic — Re-enable Progression
**Status:** 🔜 Not started (code exists, just commented out)
**Priority:** Medium — important for game flow

### Current State
In `level_select.gd`, line 10:
```gdscript
# DEV: All levels unlocked for testing (restore lock logic later)
GameManager.max_level_unlocked = 5
#GameManager.max_level_unlocked = max(GameManager.max_level_unlocked, SaveManager.load_progress())
```

The lock UI already works — disabled buttons show 🔒. The save system already tracks `max_level_unlocked`. Just needs uncommenting + testing.

### What Needs Doing

#### 4.1 Re-enable Lock Logic
```gdscript
# BEFORE (current):
GameManager.max_level_unlocked = 5

# AFTER:
GameManager.max_level_unlocked = max(GameManager.max_level_unlocked, SaveManager.load_progress())
```

#### 4.2 Verify Save/Load Cycle
1. Fresh start → only Level 1 available
2. Beat Level 1 → Level 2 unlocks
3. Close and reopen game → Level 2 still unlocked
4. Beat all 5 → all accessible
5. Edge case: what if save file is corrupt/missing? (Should default to level 1 — currently does via `load_progress() -> 1`)

#### 4.3 Visual Polish (Optional)
- Locked levels could show a dimmed icon or lock overlay instead of just 🔒 text
- Consider a "level completed" star/checkmark on beaten levels
- Highscore display already works on unlocked levels ✅

#### 4.4 Dev Toggle
Keep an easy way to unlock all levels for testing:
```gdscript
const DEV_UNLOCK_ALL = false  # Set true for testing
```

### Acceptance Criteria
- [ ] Only Level 1 available on fresh save
- [ ] Completing a level unlocks the next
- [ ] Progress persists across game restarts
- [ ] Locked levels show clear visual indicator
- [ ] Dev toggle exists for testing
- [ ] No regression — highscores still display correctly

---

## Implementation Order

| # | Task | Depends On | Est. Time |
|---|------|-----------|-----------|
| 1 | AudioManager autoload | Nothing | 1-2 hours |
| 2 | Combat sound integration | AudioManager | 1 hour |
| 3 | UI sound integration | AudioManager | 1 hour |
| 4 | Music integration | AudioManager | 30 min |
| 5 | Level lock re-enable | Nothing | 15 min |
| 6 | Settings: volume sliders | AudioManager | 1 hour |
| 7 | Settings: persistence | Volume sliders | 30 min |
| 8 | Economy: document current state | Nothing | 30 min |
| 9 | Economy: balance pass | Documentation | 1-2 hours |
| 10 | Economy: playtest + adjust | Balance pass | Ongoing |

**Total estimate:** ~8-10 hours of work across the week.

**Task 1–4** are already in progress (sub-agent working on it).
**Task 5** is a quick win — ✅ DONE (2026-02-02).
**Tasks 6-7** depend on AudioManager being done.
**Tasks 8-10** can start in parallel.

---

## Overnight Execution Protocol (2026-02-02 night)

**Martin has authorised unsupervised execution.** EDI works through the PRD overnight. Vetinari oversees via audits to ensure nothing is missed or left incomplete.

### Rules of Engagement
- **EDI** implements all 4 PRD sections without waiting for Martin's input
- **Vetinari** audits after each major section and at the end — flags anything incomplete, broken, or not meeting acceptance criteria
- **Leonard** may be spawned for art tasks if needed (new sprites, UI art, animations, tower/enemy graphics improvements)
- **Economy balancing:** EDI makes reasonable decisions based on game design principles. Martin will playtest and adjust later — get it to "good enough" first pass
- **Quality bar:** Every acceptance criterion in each section must be checked off before moving to the next
- **Git:** Commit after each section with clear messages
- **No external actions** (no publishing, no itch.io, no public posts) — internal work only

### Execution Order
1. ✅ Level lock logic (DONE)
2. Sound integration (in progress — verify/finish AudioManager + wiring)
3. Settings menus (volume sliders, persistence)
4. Economy balancing (document → balance → test mathematically)
5. Final Vetinari audit against full PRD
