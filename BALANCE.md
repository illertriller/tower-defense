# Economy Balance Analysis
**Analysed:** 2026-02-02

## Enemy Stats Summary

| Enemy | HP | Speed | Reward | Gold/HP | Notes |
|-------|-----|-------|--------|---------|-------|
| Imp | 40 | 80 | 5g | 0.125 | Trash mob, high spawn count |
| Hell Hound | 25 | 160 | 8g | 0.320 | Fast — reward premium for speed threat |
| Shadow Stalker | 50 | 100 | 12g | 0.240 | Medium speed, sneaky |
| Wraith | 60 | 90 | 12g | 0.200 | Flying — requires anti-air |
| Succubus | 70 | 75 | 18g | 0.257 | Special abilities |
| Fire Elemental | 80 | 70 | 15g | 0.188 | Medium-tanky |
| Brute Demon | 200 | 40 | 20g | 0.100 | Tank, very slow |
| Hell Knight | 250 | 50 | 30g | 0.120 | Elite |
| Bone Golem | 400 | 25 | 40g | 0.100 | Ultra-tank, glacial |
| Demon Lord | 1000 | 30 | 100g | 0.100 | Boss — big payout feels rewarding |

**Design principle:** Fast/special enemies give more gold per HP (threat premium). Tanks give less per HP but more total (they survive longer, blocking your path). Bosses give flat 100g — feels like a real reward.

## Tower Cost Analysis

| Tower | Cost | DPS | Notes |
|-------|------|-----|-------|
| Arrow Tower | 50 | 10.0 | Best value basic tower |
| Anti-Air Tower | 75 | 17.5 | Great vs flyers, 2x air bonus |
| Magic Tower | 75 | 12.0 | Slow utility, long range |
| Frost Tower | 100 | 4.0 | Heavy slow, utility > damage |
| Poison Tower | 100 | ~7.4 | DoT (5dmg + 4dot*4s = 21 per shot, 0.6 rate) |
| Cannon Tower | 100 | 15.0 | Splash makes it much more |
| Barracks | 100 | 16.0 | 2 soldiers * 8dmg, blocks path |
| Flame Tower | 125 | 24.0+ | AoE burn, amazing in choke points |
| Tesla Tower | 125 | 20.0 | Chain 3 targets = 60 effective DPS |
| Holy Tower | 125 | 14.0 | 2.5x vs elites (35 DPS vs demon types) |
| Sniper Tower | 150 | 24.0 | Single target, extreme range |
| Bomb Tower | 150 | 17.5 | Huge splash radius (80px) |
| Gold Mine | 200 | 0 | 30g/wave — ROI in 7 waves |
| Storm Tower | 200 | 42.0 | Chain 5 targets = 210 effective DPS |

## Level 1 Economy Flow

Starting gold: **100g**

| Wave | Enemies | Kill Reward | Wave Bonus | Cumulative Income |
|------|---------|-------------|------------|-------------------|
| Setup | — | — | — | 100g |
| W1 | 5 imps | 25g | 30g | 155g |
| W2 | 8 imps | 40g | 35g | 230g |
| W3 | 5 imp + 3 hound | 49g | 40g | 319g |
| W4 | 6 imp + 5 hound | 70g | 45g | 434g |
| W5 | 8 imp + 2 brute | 80g | 50g | 564g |
| W6 | 10 hound | 80g | 55g | 699g |
| W7 | 10 imp + 5 hound + 3 brute | 150g | 60g | 909g |
| W8 | 4 stalker + 8 imp | 88g | 65g | 1062g |
| W9 | 12 imp + 8 hound + 4 brute | 204g | 70g | 1336g |
| W10 | 10 imp + 5 brute + 1 hell knight | 180g | 75g | 1591g |

**Total available (L1):** 1591g — enough for ~10 mid-tier towers or 5 fully upgraded ones. Feels right for a tutorial level.

**Typical L1 build:**
- W1: 2 arrows (100g spent, 0 left)
- W2: Buy magic tower (75g) after kill income
- W3-4: Upgrade arrows or add cannon
- W5+: Expand and upgrade based on threats

## Level 5 Economy Flow

Starting gold: **200g**
Total kill rewards: **~5000g**
Total wave bonuses: **525g**
Total available: **~5725g**

Wave 10 ("HELL UNLEASHED"): 5 Demon Lords + 10 Hell Knights + 8 Bone Golems + 6 Succubi + 20 Hell Hounds = **11,620 total HP**

This requires serious investment in splash, chain, and AoE towers. Storm towers + bomb towers + flame towers in choke points should be the meta for L5.

## Gold Mine Viability Check

| Bought At | Waves Remaining | Total Return | Net Profit |
|-----------|----------------|--------------|------------|
| Wave 1 | 9 | 270g | +70g |
| Wave 2 | 8 | 240g | +40g |
| Wave 3 | 7 | 210g | +10g |
| Wave 4 | 6 | 180g | -20g (loss!) |

**Verdict:** Gold Mine must be bought by wave 3 to be profitable. This makes it a strategic early-game investment — exactly as intended. Upgrading Rich Vein makes it even more worthwhile.

## Balance Adjustments Made

| Stat | Old Value | New Value | Reason |
|------|-----------|-----------|--------|
| Bone Golem reward | 35g | 40g | 400HP should reward more; was lowest gold/HP ratio |
| Succubus reward | 20g | 18g | Slight reduction — 70HP doesn't warrant 20g alongside 200HP brute at 20g |

All other values kept. This is a first pass — Martin will playtest and we'll iterate.

## Design Notes
- **Difficulty curve works:** L1 gives easy enemies with good income. L5 throws everything at you with massive HP pools.
- **Tower diversity good:** No single tower dominates all situations. Arrow = value, Cannon/Bomb = splash, Tesla/Storm = multi-target, Frost = utility, Holy = anti-elite.
- **Upgrade path tradeoffs valid:** 4 arrow towers (200g) = 40 DPS multi-target vs 1 fully upgraded arrow (240g) = 35 DPS single-target but no space used.
- **Wave 10 L5 is appropriately terrifying.**
