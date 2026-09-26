# File map (after the split)

Every script is now under 300 lines, grouped by system. This was a move, not a refactor: functions were moved whole and their bodies are unchanged. The smoke test and the full playthrough produce the same results as before the split.

## How the big classes were split

GDScript can't spread one class over several files. So each large class became a **chain of layers**, one concern per file. Each layer `extends` the one below it, and the top layer keeps the original class name, so nothing that uses `Player`, `Enemy`, `Room` or `Game` had to change. Read a chain bottom-up: the first layer holds all the fields, and each layer above adds one concern.

This is a reading structure for distilling the prototype, not the target design. In the rebuild, each layer becomes a component or a core class (see ARCHITECTURE.md, Part 3).

| Class | Layers, bottom up | Was |
| --- | --- | --- |
| `Player` | `PlayerState` (fields, stat helpers) → `PlayerDamage` (deal, take_hit, parry, shield, heal) → `PlayerAttacks` (beat judgement, attacks, dash) → `PlayerHooks` (beat/bar runes, 4'33", Da Capo history, marks) → `PlayerMovement` (_ready, per-frame loop, jump, landing, timers) → `Player` (drawing) | `src/actors/player.gd`, 923 lines |
| `Enemy` | `EnemyState` (fields, setup, targeting) → `EnemyAttacks` (shots, waves, rings, tether, bind) → `EnemyDamage` (take_damage, stun, push, die) → `EnemyMoveAI` (per-frame behavior) → `EnemyBeatAI` (on-beat, regular Rests) → `EnemyEliteAI` (on-beat, elites; `ai_beat` entry) → `Enemy` (_ready, loop, contact, drawing) | `src/actors/enemy.gd`, 962 lines |
| `Room` | `RoomState` (fields, geometry, shared helpers, overlays) → `RoomCombat` (waves, spawns, enemy lists, Fermata) → `RoomFlow` (kills, clears, rewards, boss defeat, death, leaving) → `Room` (_ready, loop, interaction, practice stand, features, drawing) | `src/world/room.gd`, 729 lines |
| `Game` (autoload) | `GameCore` (signals, settings, save, input map) → `GameRun` (run lifecycle, items, powers) → `game.gd` (stats, sets, dissonance, routing) | `src/autoload/game.gd`, 404 lines |

## Split into separate classes

| New files | What moved | Was |
| --- | --- | --- |
| `src/audio/synth_dsp.gd` (`SynthDsp`) | buffers, fades, WAV packing, MIDI to Hz | `synth.gd`, 626 lines |
| `src/audio/synth_instruments.gd`, `synth_drums.gd`, `synth_sfx.gd` | every sample generator, now `static func` | same |
| `src/autoload/synth.gd` | buses, playback, the song sequencer (unchanged autoload) | same |
| `src/data/content/*_data.gd` (7 files) | characters, powers, runes (+ sets, dissonance), relics, enemies (+ bosses), pages (+ climb, clefs), story (teachers, intro, prologue, endings) | `content.gd`, 403 lines |
| `src/data/content.gd` | now a front door: aliases like `const POWERS = PowersData.POWERS` plus the lookup helpers, so `Content.X` still works | same |
| `src/fx/effects/*.gd` (13 files) | one file per effect (`FxBase`, `FxSlash`, `FxRing`, ...) | `fx.gd` inner classes, 429 lines |
| `src/fx/fx.gd` | now `const Ring = preload(...)` per effect, so `FX.Ring.new()` still works | same |

## Moved

| New path | Old path |
| --- | --- |
| `src/actors/player/powers.gd` | `src/actors/powers.gd` |
| `src/actors/enemies/bosses/*.gd` | `src/actors/bosses/*.gd` (paths in `EnemiesData.BOSSES` updated) |

## The only edits inside function bodies

These were needed so the layers compile. None of them changes behavior.

1. **Casts across layers.** A lower layer that passes itself to code expecting the final class now casts: `Powers.slot_of(self as Player, ...)` in the player layers, and `Layout.place_scribble(self as Room)` in `RoomFlow`.
2. **`Enemy.ai_beat` split in two.** The regular Rests' cases moved to `_beat_basic(n)` in `EnemyBeatAI`. `ai_beat(n)` in `EnemyEliteAI` passes any non-elite `ai` down to it with `if not ai.begins_with("elite_"): _beat_basic(n); return`. The two case lists never overlapped.
3. **Synth generators became static.** `_gen_keys(60)` is now `SynthInstruments.keys(60)`, and inside the generators `_buf`, `_fade`, `_hz` and `RATE` now point at `SynthDsp`.

## Full tree

```
src/
  main.gd  main.tscn
  autoload/        beat.gd  synth.gd  game.gd
    game/          game_core.gd  game_run.gd
  audio/           synth_dsp.gd  synth_instruments.gd  synth_drums.gd  synth_sfx.gd
  data/            content.gd  pal.gd  glyph.gd  loot.gd
    content/       characters_data.gd  powers_data.gd  runes_data.gd  relics_data.gd
                   enemies_data.gd  pages_data.gd  story_data.gd
  world/           layout.gd  map_gen.gd  events.gd  interactable.gd  background.gd
    room/          room_state.gd  room_combat.gd  room_flow.gd  room.gd
  actors/
    player/        player_state.gd  player_damage.gd  player_attacks.gd  player_hooks.gd
                   player_movement.gd  player.gd  powers.gd
    enemies/       enemy_state.gd  enemy_attacks.gd  enemy_damage.gd  enemy_move_ai.gd
                   enemy_beat_ai.gd  enemy_elite_ai.gd  enemy.gd
      bosses/      boss.gd  timpani.gd  flute.gd  harp.gd  conductor.gd  grand_staff.gd
  fx/              fx.gd  projectile.gd
    effects/       base.gd  slash.gd  float_text.gd  ring.gd  shockwave.gd  splat.gd  pickup.gd
                   pillar.gd  tornado.gd  decoy.gd  trail.gd  column.gd  spawn_mark.gd
  ui/              ui.gd  overlay.gd  hud.gd  choice.gd  dialogue.gd  menu_list.gd
                   loadout.gd  pause_menu.gd  map_screen.gd  title.gd  ending.gd
```

Largest files now: `powers.gd` 299, `player_damage.gd` 280, `glyph.gd` 266, `synth.gd` 253.
