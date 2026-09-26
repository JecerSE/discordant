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

## Added while fixing the playtest issues (2026-09-25)

Every tuning number for these lives in a `.tres` file under `content/`, edited in the inspector.

| File | What it is | Issue |
| --- | --- | --- |
| `content/tuning/*.tres` + `src/data/tuning/*_tuning.gd` | Tuning resources: feedback, enemy, player movement, level generation, timing, music, Timpani | all |
| `content/combat/*_attacks.tres` + `src/data/combat/attack_step.gd`, `attack_set.gd` | Each character's attack chain and down strike as data | #10 |
| `content/combat/*_combos.tres` + `src/data/combat/combo_pattern.gd`, `combo_set.gd` | Each character's rhythm combos as data | #11 |
| `src/actors/player/melee_swing.gd` | A hitbox that follows the player through a swing | #10 |
| `src/actors/player/beat_grader.gd` | Perfect / great / good / miss grades and their damage | #12 |
| `src/actors/player/combo_tracker.gd`, `combo_finishers.gd` | Spotting rhythm patterns and what each finisher does | #11 |
| `src/actors/player/powers/` | `powers.gd` (front door) plus one file per family | #29 |
| `src/actors/enemies/enemy_patrol.gd` | Idle wandering near spawn | #2 |
| `src/world/generation/` | `platform_reachability.gd`, `feature_placer.gd`, `wave_plan.gd`, `wave_planner.gd`, `spawn_picker.gd`, `bar_planner.gd` | #4 #7 #8 #25 |
| `src/world/room/damage_numbers.gd`, `src/fx/effects/damage_number.gd` | Merged damage numbers | #1 |
| `src/data/content/item_requirements.gd` | Which items need which skill | #26 |
| `src/ui/hud/` | The HUD, one widget per file | #5 #19 #20 |
| `src/ui/map/` | The map drawn as a score | #24 |
| `src/input/input_bindings.gd`, `src/ui/input_labels.gd` | Rebindable actions, saving them, readable key names | #16 #17 |
| `src/ui/settings_menu.gd`, `controls_menu.gd`, `pause_menu.gd` | Settings with sliders, rebinding screen, slim pause menu | #16 #18 |
| `src/debug/` | God mode and testing shortcuts (F1 in debug builds, or `-- --debug-menu`) | #21 |
| `tools/test_generation.gd`, `test_combat.gd`, `test_menus.gd` | Headless rule tests | |
| `tools/gen_combat_tres.py` | Writes the combat `.tres` files from tables | |

## Added for the pixel art, environments, room shapes and prologue (2026-09-26)

| File | What it is |
| --- | --- |
| `tools/art/*.py` | The seeded pixel-art generator: `pixel.py` (canvas), `palette.py`, `notes.py`, `rests.py`, `elites.py`, `bosses.py`, `npcs.py`, `props.py`, `env.py` (parallax layers, ground, planks), `logo.py`, `build.py` (writes everything) |
| `assets/sprites/`, `assets/env/`, `assets/ui/` | Generated PNGs |
| `content/art/*.tres` | One `SpriteSheet` per character, Rest, boss, teacher and prop |
| `src/art/sprite_sheet.gd`, `pixel_sprite.gd`, `art_library.gd` | Sheets as resources, a node that plays them, loading and drawing by name |
| `src/actors/player/player_animator.gd`, `src/actors/enemies/enemy_animator.gd` | Pick the animation from state; tints, squash, afterimages |
| `src/world/environment_backdrop.gd` | Sky, far and near layers (Parallax2D), tinted by the hush |
| `src/world/background.gd`, `feature_art.gd` | Staff per system, plank platforms, ground tiles, exit door; drum pads, updrafts, harmonics, strings |
| `src/world/generation/room_shape.gd` | The four fight-room shapes and how many levels each has |
| `src/world/generation/shape_builder.gd` | Width, ledger ledges, entry and exit landings, spawn and exit placement |
| `src/world/generation/staff_inker.gd` | Staff lines into platforms, for every stacked staff |
| `src/world/room/platform_ink.gd` | Platforms drawing themselves in from the spawn |
| `src/data/tuning/environment_tuning.gd`, `cinematic_tuning.gd` | Tuning for the scenery, the title and the cutscene |
| `src/data/content/intro_data.gd` | The prologue's shots: timing, captions, music, cues |
| `src/cinematic/intro_cutscene.gd`, `intro_shots.gd`, `intro_shots_below.gd` | The prologue player and how each shot is drawn |
| `src/ui/title_art.gd` | Logo, subtitle and falling note, shared by the title and the intro |
| `tools/test_art.gd` | Every sheet exists and every animation's frames are in range |
