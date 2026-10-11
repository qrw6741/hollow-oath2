# Audio (temporary)

All sound is **placeholder, synthesised in code** by `tools/audio/gen_audio.py` (sine waves, noise, filters, a simple reverb). No samples, so there is nothing to license. Regenerate after editing the script:

```
python3 tools/audio/gen_audio.py      # needs numpy, scipy and ffmpeg with libvorbis
```

Files: `assets/audio/sfx/*.wav` (44.1 kHz mono) and `assets/audio/music/*.wav` (22.05 kHz mono, sample-exact loops; reverb tails wrap so there is no seam). To replace a sound with a real one, overwrite the `.wav` with the same name.

## How it is wired
- `Audio` autoload: `Audio.sfx(name)`, `Audio.sfx_at(name, world_pos)` (pans/fades with distance), `Audio.music(track)` (crossfade, looping), `Audio.sting(name)`. Buses: Master > Music, SFX. Volumes in Settings (Volume / Music / Effects).
- Player sounds: `actors/player/player_sounds.gd` watches the player (swings per weapon type, hits, parry clang, dodge, jump, land, footsteps, hurt, heal, death).
- Enemies: `EnemyBase.play_attack_sound()` / `play_death_sound()`; the Bell-Warden tolls its bell on every overhead wind-up (an audio telegraph), stomps, lands, roars and cracks on death.
- World / UI events (embers, pickups, level-up, save, rest, gate seal, victory sting) are connected in `Audio._connect_events()`; menu buttons tick on focus and select.
- Music: `menu` (main menu), level `music` export (`yard` = wind and distant bells), `boss` (drums, low strings, bell) during boss fights, silence + `victory` sting after a win, fade out on death.

## Sound list
Combat: swing_light, swing_heavy, swing_fist, hit_flesh, hit_armor, hit_crit, parry, hurt, death, dodge, jump, land, step_1/2, heal.
World: rest, ember, pickup, levelup, save, gate_seal, victory. Enemies: enemy_windup, enemy_death. Boss: boss_bell, boss_stomp, boss_land, boss_roar, boss_death. UI: ui_move, ui_select, ui_back.

Mixing levels were set by measuring peak/RMS, **not by listening** (the dev environment has no speakers). Expect to rebalance after the first listen.
