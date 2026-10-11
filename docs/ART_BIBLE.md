# Art Bible — v0.1

This defines the target for final art. Current in-game visuals are procedural placeholders that already follow the palette and proportions below so the switch to sprites is a like-for-like swap.

## Resolution & pixel density
- Internal resolution **480 × 270**, integer-scaled (×3 at 1440×810, ×4 at 1920×1080). No sub-pixel sprites; no rotated pixel art except FX.
- **1 tile = 16 px.** Doors 2×3 tiles; standard jump clears ~3 tiles.
- Texture filter: nearest everywhere.

## Proportions
| Character | Height | Collision box | Notes |
|---|---|---|---|
| Oathbound (player) | 28 px | 10 × 26 | Head ≈ 1/4 height; reads by the **bone-white mask** and **crimson sash** |
| Hollow Penitent | 34 px (hunched) | 14 × 30 | Reads by the **ember eye** and **rust blade** |
| Major bosses | 64–160 px | per design | Must fill ≥ 1/3 of the screen height |

Origin / pivot = **centre of the feet** for every character. Sprite frames are padded so the pivot stays on the same pixel in every frame.

## Palette (master — `systems/palette.gd`)
| Role | Colour |
|---|---|
| Deep black / outlines | `#0d0b10` |
| Night / sky | `#0b0a12` → `#2a1f2c` |
| Stone dark / mid / light | `#2b2830` `#45414b` `#6a6570` |
| Dust | `#8d867e` |
| Bone / bone dim | `#d9d0bc` `#a69d8a` |
| Cloth dark / light | `#221e28` `#3a3442` |
| Steel / oxidised steel / rust | `#8b9290` `#5e6f69` `#7a3e22` |
| Crimson / crimson bright | `#8e1b22` `#c4313a` |
| Gold / gold bright (restrained) | `#c9a24a` `#efd27e` |
| Ember | `#e0702a` |
| Wood / wood light | `#4b3627` `#6d523b` |

### Colour language (gameplay-critical)
- **Gold** = the player's good things: parry success, riposte cue, healing, checkpoints. Never used on enemies' threats.
- **Crimson bright** = danger now: enemy blade glint (attack about to land), player damage.
- **Ember** = hostile life: enemy eyes, enemy death.
- **Bone white** = the player's head and readable highlights. Keep enemies' brightest tone below the player's mask.
- Backgrounds stay in the low-value range so the playable layer always has more contrast.

## Animation conventions
- 60 fps logic; sprite animations authored at **12 fps** (5 game frames per sprite frame) except attacks, which are authored **per game-frame phase**: anticipation frames must cover the whole `startup_frames`, one smear frame for `active`, the rest recovery.
- Every attack needs: clear wind-up pose held long enough to read, a smear/trail frame, and a recovery that returns to idle.
- Enemy telegraph: the final **12 frames before active** must contain a visible cue (glint, eye flare).
- Required player animations (M4): idle, run, jump-up, jump-apex, fall, land, light 1/2/3, heavy, air attack, dodge roll, parry, parry-success, riposte, heal, hurt, death, rest-kneel, rise.

## Layers & depth
| Layer | Parallax | Content |
|---|---|---|
| Sky | 0 | Gradient, moon |
| Far | 0.15 | Spires, distant lit windows |
| Mid | 0.4 | Cathedral masses, arches |
| Near | 0.7 | Dead trees, broken walls |
| Playable | 1.0 | Terrain, actors |
| Foreground (M5) | 1.2–1.4 | Dark silhouettes, chains, hanging cloth; never covers the player for more than ½ s of movement |

Darkness via `CanvasModulate`; light via `PointLight2D` (candles, player lantern).

## UI style
Thin bars with bone-coloured end caps; crimson health, moss-green stamina, gold vial icons. Titles in caps with generous letter spacing (custom pixel font planned). No pure white text — use bone.

## Naming rules
- Files: `snake_case`. Scenes `name.tscn`, scripts `name.gd`, data `name.tres`.
- Sprite sheets: `<character>_<animation>.aseprite` → exported `<character>_<animation>.png` + `.json`, e.g. `oathbound_attack_light1.png`.
- Animation names inside sheets match `AttackData.animation` / state names (`idle`, `run`, `slash`, `heavy`, `air`, `riposte`...).
- Mark any temporary asset with `TEMP_` prefix or a `TEMPORARY ART` header comment.

## Export pipeline (Aseprite → Godot), for M4
1. One `.aseprite` per character, tags per animation, canvas size fixed per character (player: 64×48), pivot marker layer hidden on export.
2. Export: `aseprite -b oathbound.aseprite --sheet oathbound.png --data oathbound.json --format json-array --list-tags --sheet-type packed`.
3. Import into Godot as `SpriteFrames` via the import script to be added in M4 (no third-party plugin required), with frame durations from the JSON.
4. Verify in the capture scene that the pivot does not drift between animations.
