# PRD — Intro Cinematic: "Hell Marches"
**Created:** 2026-02-04
**Owner:** Leonard (design) + EDI (scripting/assembly)
**Tool:** xAI Grok Imagine API (grok-imagine-video / grok-imagine-image)
**Budget:** $15 xAI credits (be strategic — test small, iterate)

---

## 1. Concept

A short cinematic intro (30-60 seconds assembled) that plays before the main menu or on first launch. Shows a wave of demonic enemies marching down a path, then getting obliterated by tower defences. Sets the tone: hell is coming, but you're ready.

**Style:** Dark fantasy, hellfire atmosphere. Should feel like a dramatic movie trailer for our tower defense game. NOT pixel art — this is a cinematic interpretation of the game world. Think "what the battle looks like from ground level."

---

## 2. Scene Breakdown

### Scene 1 — "The March" (~3-4 clips)

**Setup:** A hellish landscape. A dirt/stone path winding through scorched terrain. Ominous red sky.

| Clip | Duration | Description | Prompt Direction |
|------|----------|-------------|-----------------|
| 1A | ~5s | Wide establishing shot — a horde of demons marching along a winding path through a hellish landscape. Red sky, embers in the air. Camera slowly pulling back to reveal the scale. | `"Wide cinematic shot of a demon army marching along a winding dirt path through a dark hellish landscape, red sky with embers, fantasy dark atmosphere, dramatic lighting, camera pulling back"` |
| 1B | ~5s | Close-up of the **Brute Demon** — a massive red-skinned beast stomping forward, earth shaking with each step. Other smaller demons scatter around its feet. | `"Close-up cinematic shot of a massive red-skinned brute demon stomping forward on a dirt path, enormous muscular beast, smaller demons around its feet, dark fantasy, dramatic low angle, hellfire atmosphere"` |
| 1C | ~5s | **Succubus** gliding through the ranks — elegant, dangerous, wings spread. Camera tracks her as she passes lesser demons. | `"Cinematic tracking shot of a dark succubus with wings gliding elegantly through ranks of marching demons, seductive and dangerous, dark fantasy atmosphere, dramatic lighting"` |
| 1D | ~5s | Pack of **Hell Hounds** sprinting ahead of the main force — fast, feral, flames licking from their jaws. Ground-level camera as they rush past. | `"Ground-level cinematic shot of demonic hell hounds sprinting past the camera, flaming jaws, feral and fast, pack of demon dogs running on a dirt path, dark fantasy, motion blur, dramatic"` |

### Scene 2 — "The Defences" (~2 clips)

**Setup:** Camera reveals towers positioned along the path. Calm before the storm.

| Clip | Duration | Description | Prompt Direction |
|------|----------|-------------|-----------------|
| 2A | ~5s | Reveal shot — camera pans up to show a **Tesla Tower** crackling with electricity, arcs of lightning dancing between its coils. It hums with power, waiting. | `"Cinematic reveal shot of a tesla coil tower crackling with blue-white electricity, arcs of lightning between metal coils, dark fantasy medieval tower defense, dramatic upward camera pan, ominous atmosphere"` |
| 2B | ~5s | A row of **Cannon Towers** — heavy stone fortifications with iron barrels. Camera slowly tracks along them. Fuses light. | `"Cinematic tracking shot along a row of medieval cannon towers, heavy stone fortifications with iron cannon barrels, fuses igniting, dark fantasy atmosphere, dramatic lighting, preparing for battle"` |

### Scene 3 — "The Slaughter" (~3-4 clips)

**Setup:** The demons reach the kill zone. Towers open fire. Chaos and destruction.

| Clip | Duration | Description | Prompt Direction |
|------|----------|-------------|-----------------|
| 3A | ~5s | Tesla Tower fires — a massive chain lightning bolt rips through a group of Hell Hounds, electricity arcing between them. They convulse and shatter. | `"Cinematic shot of a tesla tower firing chain lightning at demon dogs, massive electrical bolt arcing between multiple targets, demons being electrocuted and destroyed, dark fantasy battle, dramatic VFX, explosive"` |
| 3B | ~5s | Cannon Tower barrage — cannonballs slam into the Brute Demon. Explosions. The beast staggers but keeps coming. More cannons fire. | `"Cinematic shot of cannon towers firing at a massive red brute demon, cannonball explosions impacting the beast, smoke and fire, the demon staggers, dark fantasy siege battle, dramatic slow motion"` |
| 3C | ~5s | The Brute finally goes down — a massive Tesla strike combined with cannon fire brings it crashing to the ground. Dust cloud. Smaller demons scatter. | `"Cinematic shot of a massive red demon collapsing to the ground after being hit by lightning and cannon fire, huge dust cloud, smaller demons fleeing, dark fantasy battle victory moment, dramatic"` |
| 3D | ~5s | Final wide shot — the battlefield is smoking wreckage. Towers stand victorious. Camera pulls up and away. | `"Wide cinematic aerial shot of a fantasy battlefield after a battle, smoking wreckage, defensive towers standing victorious among destroyed demons, dark atmosphere, embers rising, camera pulling away"` |

### Scene 4 — "Title Card" (~1 clip or static image)

| Clip | Duration | Description | Prompt Direction |
|------|----------|-------------|-----------------|
| 4A | Static | Game title appears over the smoking battlefield or a dramatic hellscape background. This can be an image rather than video. | `"Dark fantasy game title screen background, hellish landscape with defensive towers silhouetted against a red sky, embers and smoke, cinematic wide shot, dramatic lighting"` |

---

## 3. Production Plan

### Phase 1 — Test & Calibrate (Budget: ~$3)
1. Generate 2-3 test images with `grok-imagine-image` to nail the visual style
2. Generate 1 test video clip to assess quality, motion, and coherence
3. Evaluate: Does it look good enough? Adjust prompts based on results
4. **Decision gate:** Martin reviews test output before proceeding

### Phase 2 — Generate Clips (Budget: ~$8)
1. Generate each scene clip using `grok-imagine-video`
2. For scenes needing a specific look, generate a reference image first, then use image-to-video
3. Expect 2-3 attempts per clip for quality (some will need re-prompting)
4. Save all outputs for Martin to review and pick favourites

### Phase 3 — Assembly (Budget: ~$2 reserve)
1. Use ffmpeg to stitch selected clips together
2. Add fade transitions between scenes
3. Overlay game title (Scene 4)
4. Add music track (we have `menu_theme` and `battle_loop` in assets)
5. Optional: Add sound effects from our existing combat audio

### Phase 4 — Integration
1. Export as `.webm` or `.ogv` for Godot compatibility
2. Create a `VideoStreamPlayer` scene for the intro
3. Wire into game launch sequence (skip on button press)

---

## 4. Technical Notes

### API Details
- **Image endpoint:** `POST https://api.x.ai/v1/images/generations`
- **Video endpoint:** Async — submit request, poll for result
- **Image model:** `grok-imagine-image`
- **Video model:** `grok-imagine-video`
- **Max video input:** 8.7 seconds
- **Auth:** Bearer token (stored in TOOLS.md)

### Assembly Tools
- `ffmpeg` for stitching, transitions, audio overlay
- Godot `VideoStreamPlayer` for in-game playback

### Budget Tracking
| Item | Est. Cost | Actual |
|------|-----------|--------|
| Test images (3-5) | $0.50 | — |
| Test video (1-2) | $1.50 | — |
| Scene clips (10-12 attempts) | $7.00 | — |
| Title card image | $0.50 | — |
| Re-generations / fixes | $2.00 | — |
| **Reserve** | **$3.50** | — |
| **Total budget** | **$15.00** | — |

*Note: Actual pricing TBD — costs above are rough estimates. We'll track actual spend as we go.*

---

## 5. Acceptance Criteria
- [ ] 30-60 second assembled cinematic
- [ ] Visually coherent style across all clips
- [ ] Features: Brute Demon, Succubus, Hell Hounds, Tesla Tower, Cannon Tower
- [ ] Includes tower destruction of enemies (the payoff moment)
- [ ] Title card at the end
- [ ] Music overlay from existing game assets
- [ ] Skippable in-game
- [ ] Martin approves final cut

---

## 6. Risks & Mitigation
| Risk | Impact | Mitigation |
|------|--------|------------|
| Video quality too low / incoherent | Can't use clips | Test first (Phase 1), adjust prompts, use image-to-video for more control |
| Budget burns too fast | Can't complete all scenes | Prioritise Scene 1B (Brute) + Scene 3A (Tesla) as hero moments. Cut lesser scenes |
| Style inconsistency between clips | Doesn't feel like one movie | Generate reference image first, use as seed for all clips. Consistent prompt prefix |
| API rate limits | Slow production | Space requests, work in batches |

---

*Don't start production until Martin gives the green light.*
