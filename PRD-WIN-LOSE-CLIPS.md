# PRD — Win & Lose Cinematics
**Created:** 2026-02-04
**Owner:** Leonard (design) + EDI (assembly) + Vetinari (oversight)
**Tool:** xAI Grok Imagine API (grok-imagine-video / grok-imagine-image)
**Budget:** ~$4-5 from remaining xAI credits

---

## 1. Concept

Two short cinematic clips that play at the end of a level:
- **WIN** — Towers blast the demons to pieces. Victory!
- **LOSE** — Demons smash through crumbling towers. Defeat.

Both should be 5-10 seconds of video ending on a still frame with text overlay. Quick, punchy, emotionally clear.

---

## 2. Win Cinematic — "Victory"

### Video Clip (~5-7 seconds)
A dramatic scene of towers obliterating the enemy wave. The Brute Demon, Succubus, and Hell Hounds are caught in a barrage of tower fire — lightning, explosions, destruction. The enemies are overwhelmed and destroyed. Towers stand victorious.

**Prompt direction:**
`"Cinematic dark fantasy battle scene, defensive towers firing lightning bolts and explosions at a group of demons including a massive red brute demon, a winged succubus, and demonic hell hounds, the demons are being destroyed and overwhelmed, explosions and lightning everywhere, towers standing strong and victorious, dramatic lighting, epic victory moment"`

### Still Frame + Text
- Final frame holds as a still
- Text overlay: **"VICTORY!"** in gold/amber colour
- Cinzel Decorative Bold font (matching intro cinematic)
- Subtle glow/bloom effect on text if possible
- Duration of still: ~3 seconds
- Fade to black at end

### Total duration: ~8-10 seconds

---

## 3. Lose Cinematic — "Defeat"

### Video Clip (~5-7 seconds)
The opposite — demons breaking through the defensive line. The Brute Demon smashes a tower apart, Hell Hounds rush past crumbling defences, the Succubus flies overhead triumphantly. Towers are destroyed, walls crumble. The defence has fallen.

**Prompt direction:**
`"Cinematic dark fantasy scene, a massive red brute demon smashing through a medieval defense tower, the tower crumbles and collapses, demonic hell hounds rush past broken defenses, a winged succubus flies overhead triumphantly, towers destroyed and burning, smoke and rubble, the demons have won, dark dramatic atmosphere, defeat and destruction"`

### Still Frame + Text
- Final frame holds as a still
- Text overlay: **"GAME OVER"** in deep red colour
- Cinzel Decorative Bold font (matching intro cinematic)
- Duration of still: ~3 seconds
- Fade to black at end

### Total duration: ~8-10 seconds

---

## 4. Production Plan

### Phase 1 — Generate Clips
1. Generate 1 reference image per clip (win scene, lose scene) to establish the look
2. Generate video clip from each reference using image-to-video
3. Expect 1-2 attempts per clip (we've got the prompt style dialled in from the intro)

### Phase 2 — Assembly
1. Extract final frame from each video clip
2. Overlay text ("VICTORY!" / "GAME OVER") on the final frame using ffmpeg
3. Stitch: video → freeze frame with text (3s) → fade to black
4. Add audio: victory_theme.ogg for win, defeat sound for lose (from existing game assets)

### Phase 3 — Delivery
1. Export as mp4, same specs as intro cinematic
2. Files: `win_cinematic.mp4` and `lose_cinematic.mp4`
3. Save to `projects/tower-defense/assets/cinematic/`

---

## 5. Budget Estimate

| Item | Est. Cost |
|------|-----------|
| Reference images (2) | $0.30 |
| Video generation (2-4 attempts) | $3.00 |
| **Total** | **~$3.30** |

*Comfortable within remaining budget.*

---

## 6. Audio Mapping

| Clip | Music | Source |
|------|-------|--------|
| Win | `victory_theme.ogg` | `assets/audio/music/victory_theme.ogg` |
| Lose | Battle music fading out / defeat sting | `assets/audio/music/battle_loop.ogg` (fade out) |

---

## 7. Acceptance Criteria
- [ ] Win clip: 8-10 seconds, towers destroying brute/succubus/hounds, ends with "VICTORY!" still frame
- [ ] Lose clip: 8-10 seconds, demons smashing through towers, ends with "GAME OVER" still frame
- [ ] Consistent visual style with intro cinematic
- [ ] Font matches intro (Cinzel Decorative Bold)
- [ ] Music overlaid from existing game assets
- [ ] Martin approves both clips

---

*Awaiting Martin's green light before production begins.*
