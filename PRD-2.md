# PRD-2 — Tower Defense: Visual Polish & Code Quality
**Created:** 2026-02-02
**Follows:** PRD.md (Sound, Economy, Settings, Level Lock — all ✅)
**Owner:** EDI + Leonard
**Oversight:** Vetinari audits after each section

---

## 1. 🎨 Walk Animation Quality Pass
**Status:** 🔜
**Priority:** Medium
**Owner:** Leonard

### Current State
All 10 enemy walk sheets exist (256x64, 4 frames each at 64x64). However, 4 frames is minimal — smoother walks need 6-8 frames. Need to verify quality of each sheet.

### What Needs Doing

#### 1.1 Audit Walk Sheet Quality
Check each of the 10 walk sheets visually:
- Do they look like proper walk cycles or static poses shuffled?
- Is the art style consistent across all 10?
- Are any obviously placeholder quality?

Enemies to check:
1. `imp_walk_sheet.png`
2. `hell_hound_walk_sheet.png`
3. `brute_demon_walk_sheet.png`
4. `wraith_walk_sheet.png`
5. `fire_elemental_walk_sheet.png`
6. `shadow_stalker_walk_sheet.png`
7. `bone_golem_walk_sheet.png`
8. `succubus_walk_sheet.png`
9. `hell_knight_walk_sheet.png`
10. `demon_lord_walk_sheet.png`

#### 1.2 Upgrade Low-Quality Sheets
For any sheet that's clearly low quality or inconsistent:
- Regenerate using PixelLab at 64x64 with 6-8 frames
- Use the existing static sprite (`*_enemy.png`) as style reference
- Match the dark fantasy / demon theme
- Output as horizontal sprite sheet (frames × 64x64)

#### 1.3 Update Code If Frame Count Changes
If any sheet gets more frames, update `enemy.gd` `_setup_animation()` — it currently auto-detects frame count from sheet width, so this should work automatically as long as frame_width stays 64.

### Acceptance Criteria
- [ ] All 10 walk sheets visually audited
- [ ] Any low-quality sheets regenerated
- [ ] Walk animations look smooth in-game (no obvious jank)
- [ ] Consistent art style across all enemy types

---

## 2. 💀 Enemy Death Animations
**Status:** 🔜
**Priority:** Medium
**Owner:** Leonard + EDI

### Current State
One generic `death_poof_sheet.png` (256x64, 4 frames) used for ALL enemy types. Works but feels generic.

### What Needs Doing

#### 2.1 Create Type-Specific Death Effects
Generate death animations for enemy categories (don't need 10 unique ones — categories are fine):

| Category | Enemies | Effect Style |
|----------|---------|-------------|
| Fire death | imp, fire_elemental, hell_hound | Flame burst, ember particles |
| Shadow death | wraith, shadow_stalker, succubus | Dark mist dissolve, purple wisps |
| Heavy death | brute_demon, bone_golem, hell_knight | Ground shake particles, debris |
| Boss death | demon_lord | Dramatic explosion, larger, multi-stage |

Each death animation: 64x64 sprite sheet, 4-6 frames.

#### 2.2 Wire Death Animations Into Code
Update `scripts/effects/particles.gd` (`spawn_death_poof`) to accept enemy type and select the appropriate death sheet:
```gdscript
func spawn_death_effect(tree: SceneTree, pos: Vector2, enemy_type: String):
    # Select death animation based on enemy category
    # Fire / Shadow / Heavy / Boss
```

Update `enemy.gd` `die()` to pass enemy_type to the death effect.

### Acceptance Criteria
- [ ] At least 3 death animation categories created (fire, shadow, heavy)
- [ ] Boss death is visually distinct and impressive
- [ ] Death animations wired into the game per enemy type
- [ ] Generic poof kept as fallback for any missing type

---

## 3. 🖼️ UI Art Polish
**Status:** 🔜
**Priority:** Medium
**Owner:** Leonard + EDI

### Current State
UI art exists: panel frames, button sprites, tower slots, minimap frame, topbar, decorations (ornaments, gems, dividers, emblems). Need to verify what's actually being used vs what's orphaned, and whether the in-game UI looks polished.

### What Needs Doing

#### 3.1 Audit UI Art Usage
Check which sprites are actually referenced in scene files vs just sitting in the folder:
```bash
grep -r "sprites/ui" scenes/ scripts/ --include="*.gd" --include="*.tscn"
```

#### 3.2 Polish HUD Panel
The in-game HUD (`game_hud.gd` / `game_hud.tscn`) should use the WC3-style panel art:
- Bottom panel uses `ui_panel_bg.png` (1280x120)
- Tower slots use `ui_tower_slot_bg.png` / `ui_tower_slot_selected.png`
- Info panel uses `ui_info_panel_bg.png`
- Topbar uses `topbar_frame.png`
- Verify all are properly integrated

#### 3.3 Menu Visual Polish
- Start menu should look professional (backdrop + ember effects already exist)
- Level select should use consistent styling
- Settings panel already styled (dark gold theme) ✅
- Win/lose screens should feel impactful

#### 3.4 Missing UI Elements
Check if we need:
- [ ] Tower tooltip/info popup art
- [ ] Wave counter bar art
- [ ] Resource (gold/lives) icon sprites
- [ ] Level select card/button art

### Acceptance Criteria
- [ ] All existing UI art is actually used in-game (no orphaned sprites)
- [ ] HUD panel looks polished with WC3-style art
- [ ] Menus are visually consistent
- [ ] No programmer-art placeholder buttons visible in final game

---

## 4. 🐛 Code Review & Bug Hunt
**Status:** 🔜
**Priority:** High
**Owner:** EDI

### What Needs Doing

#### 4.1 Static Code Review
Read through all .gd files and check for:
- Unused variables / dead code
- Potential null reference errors (missing `is_instance_valid` checks)
- Signal connection leaks
- Performance issues (expensive operations in `_process`)
- Inconsistent naming conventions

#### 4.2 Known Issue: Error Sound
The AudioManager has an `error` sound loaded. Verify it's used when:
- Player tries to place tower they can't afford
- Player tries to place on invalid tile
- Player tries to upgrade when can't afford

#### 4.3 Known Issue: Level Lock
Verify the level lock change works correctly:
- Fresh save → only Level 1 available
- Beat Level 1 → Level 2 unlocks
- Progress saved to disk

#### 4.4 Known Issue: Gold Mine Wave Income
Verify gold mine awards income correctly when wave starts (not on enemy kill).

#### 4.5 Audio Edge Cases
- What happens if you open settings during gameplay? Music shouldn't restart.
- What happens if you ESC → settings → change volume → resume? Should work smoothly.
- Overlapping death sounds when many enemies die at once — SFX pool handles this?

### Acceptance Criteria
- [ ] No obvious bugs found (or all found bugs fixed)
- [ ] Error sound plays on failed actions
- [ ] Gold mine income verified working
- [ ] Audio works correctly across all game states
- [ ] Code is clean — no dead code, proper null checks

---

## 5. 📦 Export Preparation
**Status:** 🔜
**Priority:** High
**Owner:** EDI

### What Needs Doing

#### 5.1 Verify Godot Export Templates
Check if Godot export templates are installed for:
- HTML5/Web
- Windows Desktop
- Linux (optional bonus)

#### 5.2 Project Settings for Web
- Ensure project resolution / stretch mode works well in browser
- Check that all audio loads correctly in web context (Web Audio API)
- Verify mouse input works (no right-click browser menu conflicts)

#### 5.3 Test Build
- Export HTML5 build and test locally
- Export Windows .zip and verify it runs
- Check file size (target <50MB for web)

#### 5.4 itch.io Page Prep
Prepare assets for the itch.io page (don't publish yet — Martin will review):
- [ ] Cover image (315×250 minimum, preferably 630×500)
- [ ] 3-4 gameplay screenshots
- [ ] Game description draft
- [ ] Tags: tower-defense, pixel-art, fantasy, strategy, demons, godot

### Acceptance Criteria
- [ ] HTML5 build exports and runs in browser
- [ ] Windows build exports and runs standalone
- [ ] Build size under 50MB
- [ ] Cover image and screenshots prepared
- [ ] itch.io description drafted

---

## Implementation Order

| # | Task | Owner | Est. Time | Depends On |
|---|------|-------|-----------|------------|
| 1 | Walk animation audit | Leonard | 30 min | Nothing |
| 2 | Regenerate low-quality walks | Leonard | 1-2 hours | Audit |
| 3 | Death animation sprites | Leonard | 1-2 hours | Nothing |
| 4 | Wire death animations | EDI | 30 min | Death sprites |
| 5 | UI art audit + polish | EDI + Leonard | 1 hour | Nothing |
| 6 | Code review + bug fixes | EDI | 1-2 hours | Nothing |
| 7 | Export prep + test builds | EDI | 1 hour | Nothing |
| 8 | Vetinari final audit | Vetinari | 30 min | All above |

**Total estimate:** ~6-8 hours

## Overnight Execution Protocol

Same rules as PRD-1:
- **EDI** implements code tasks, spawns **Leonard** for art tasks
- **Vetinari** audits after each major section
- No external actions (no publishing)
- Git commit after each section
- Don't message Martin unless critically broken
