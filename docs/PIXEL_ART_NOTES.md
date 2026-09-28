# Pixel-art transition: notes

> **Correction (2026-09-27).** Every "smoke runs 24635 frames on main and this branch" below
> was not evidence. Before main's commit fcf19da, tools/smoke.gd never seeded the global
> RNG, so each run played a different run (new_run() takes its seed from that RNG, which
> Godot seeds randomly at launch) and its frame count varied on unchanged code: 24635,
> 24615, 24603 and a crash were all measured on the same commit. The matches were
> coincidence. Until that fix, the only real isolation checks were the fixed-seed
> fingerprint (tools/test_rng_streams.gd, identical to main at every commit) and
> tools/compare_rng_streams.sh (3/3 at every commit). From fcf19da on, smoke is seeded and
> run with --fixed-fps 60: two runs give identical logs and the same count (24603), so the
> frame count comparison is a real check.
>
> **Correction (2026-09-27): clipped placeholders.** The placeholder generator rendered on a
> canvas with only 40 px below the origin, so three committed placeholders were cut off
> (floor tile, Alto clef, Fallen Cellist) while pipeline/check_placeholders.gd reported them
> as matching: it drew the code version and the sprite through the same too-small canvas,
> so both were clipped identically. Fixed in c316d0f (bigger canvas, and the generator now
> fails any drawing that touches the canvas edge). A full recheck after the fix: 98
> placeholders regenerated with no edge hits and no file changes; 96 checked, 0 failing
> (the two platform tiles are cropped by design and checked in game screenshots).
>
> **The lesson.** A checker that renders both sides through the same faulty path cannot
> detect that fault. Four checks in this project have now been trusted before being shown
> to fail: the immortal sweep bot (win rate and deaths meant nothing), the zeroed
> playthrough telemetry (kills and sharps printed after the run was cleared), the unseeded
> smoke test (its frame count varied on unchanged code), and the clipped canvas. Before
> trusting a new check, make it fail once on purpose.

## Phase 0 (done)

Internal resolution 480x270, stretch mode `viewport`, aspect `keep`, integer scaling,
window 1440x810. 480x270 is exactly 4x at 1080p and shows about 2.5 staff lines; 384x216
showed only two, too few for a game about climbing five. Only `project.godot` changed.
Every `_draw()` is untouched, so anything laid out for 1280x720 (HUD, announcements, map,
menus, title) currently overflows the top-left corner. That is expected until Phase 2.

Nothing in `src/` reads the viewport size, so the change cannot reach the simulation.
Headless suites pass unchanged; smoke runs 24635 frames on both main and this branch.

## Phase 1a: the UI layer (done)

Decision: the UI stays at native resolution over a scaled pixel world (option b), instead
of redesigning every screen for 480x270 (option a). Reasons: the game has no pixel font on
this branch, the HUD and menus are dense text (item descriptions, tuning of runes, the map
score) that would not fit legibly in 480x270 units, and many pixel games (Dead Cells,
Celeste's menus) keep crisp UI over a low-res world. The pixel look comes from the world.

How: the root window is back to a 1280x720 base with `canvas_items` stretch (UI layouts
unchanged). `WorldView` (src/ui/world_view.gd) renders rooms in a 480x270 SubViewport with
nearest filtering, shown full screen: exactly 3x at 1440x810 and 4x at 1080p (other window
sizes scale non-integer). When `Main` shows a room it hosts it in the WorldView and lifts
the room's HUD CanvasLayer up to full resolution, freeing it with the room. Title, map,
ending and every overlay draw at full resolution. Nothing in src/ reads the viewport size,
and the world has no mouse or GUI input, so the split is presentation only.

### Phase 1b: whole-number scaling (done)

The world view is always drawn at the largest whole-number scale that fits the window,
centred, with a dark frame around it; the full-resolution UI covers the whole window.
Stretch aspect is `expand` (no letterbox bars: a fractional bar shifted the image by a
fraction of a pixel at 1366x768) and `2d/snap/snap_2d_transforms_to_pixel` is on.
Verified by comparing screenshots block by block with the world view's own 480x270
image: 0 of 129600 world pixels misplaced at 1280x720 (2x), 1440x810 (3x), 1600x900 (3x),
1920x1080 (4x), 1366x768 (2x), 1000x700 (2x) and fullscreen 2880x1800 (6x).

### Text in the world

**Pixelate with the world.** Shop prices, statue and teacher names, damage numbers and
float text stay where they are drawn today, inside the 480x270 world, and scale with it.
No plumbing: the world stays one self-contained picture, text sits exactly on the
sprites it labels, and it moves and shakes with the camera for free. The cost is
legibility and looks: at 480x270 an 18 px serif becomes a muddy, chunky blur rather than
pixel art, so this path only works with a real bitmap font designed for 6 to 10 world
pixels (digits for damage, a small alphabet for labels). Small text such as
"Buy Gold Leaf (50#)" or item names may not fit legibly at that size.

**Draw on the UI layer at projected positions.** World code keeps deciding what to show
and where, but the text is painted by the full-resolution layer at the world position
projected to the screen (world view transform: camera, whole-number scale, offset).
Everything stays crisp and readable at any window size, including the timing grades
("perfect!") that are core feedback in a rhythm game. The cost is plumbing and some care:
a projection helper, a text layer that follows the camera and shake, snapping the
projected position to the world pixel grid so text doesn't shimmer against sprites, and
moving the drawing of damage numbers, float text and interactable labels (room/ and
interactable code) onto that layer.

**DECIDED: the UI layer.** Gameplay text (damage numbers, float text, grade callouts,
prices, labels) is drawn crisp on the full-resolution layer at projected world positions.
It needs a projection helper that follows the world view's camera and shake (camera
transform, whole-number scale, view offset), snapped to the world pixel grid.

Original recommendation, kept for the record: **the UI layer.** This game's text is gameplay information: grades,
damage, prices, what an item does. Crisp and readable beats stylistic purity, and it
matches the Phase 1a decision (crisp UI over a pixel world). It also keeps the font
question open: the same layer can use a pixel-style font later without pixelating.

Left for Phase 2: text drawn in world space (shop prices, teacher and statue names,
damage numbers, float text) renders at 480x270 and looks pixelated.

## Findings that block Phase 1

1. **Main is not deterministic.** Two playthroughs with the global RNG seeded to the same
   value (a wrapper script that calls `seed()` before `tools/playthrough.gd`) diverge at
   room 2: different map paths, 105116 vs 113073 frames. Likely causes:
   - `EnemyPatrol` seeds its RNG from `get_instance_id()`, which is not stable between runs.
   - About 31 files in `src/` draw from Godot's global RNG, shared by simulation and cosmetics
     (for example camera shake in `Room._physics_process`).
   Also: `playthrough.gd` prints kills/sharps/relics as 0 because the run is cleared before it
   prints, so that line is not usable telemetry yet.
2. **Rendering already consumes simulation randomness.** `src/world/background.gd` takes its
   grain and blobs from `room.rng` in `setup()`, which runs before `_build_waves()` uses the
   same `room.rng`. Any change to how the background draws changes the waves. Phase 1 must
   give rendering its own cosmetic stream.

Phase 1 stays blocked until determinism lands on main and the fixed-seed telemetry proof
(same seed, identical kills, damage, items and rooms on main and on this branch) can run.

## Phase 1c: asset pipeline and swap mechanism (done)

**Folders.** `assets/sprites/<key>.png` holds each sprite (placeholders first, real art
later). `content/art/sprites/<key>.tres` is a `SpriteArt` (texture + the origin pixel that
sits on the node's position). `content/art/render_flags.tres` lists which keys draw from
sprites.

**Import presets** (`[importer_defaults]` in project.godot): lossless (no compression),
no mipmaps, no 3D VRAM compression, no alpha-border fixing. Filtering is not an import
setting in Godot 4: the world view sets `canvas_item_default_texture_filter` to nearest,
so every sprite in the world is drawn nearest.

**Git policy for import metadata (verified).** Commit `*.import` next to each asset, and
the `*.uid` files next to scripts; ignore `.godot/` (the import cache). Verified by
deleting `prop_sign.png.import` and re-importing: the texture got a new uid
(`uid://cv2cdmdqtcdfd` became `uid://bajj3c2j3og4a`). Without the `.import` files every
clone would give assets new uids (breaking uid references in scenes and resources) and
lose per-file import settings. `*.import` was removed from `.gitignore`.

**Swap mechanism.** `RenderAdapter.draw_sprite(canvas_item, key)` draws the sprite and
returns true when `key` is listed in `render_flags.tres` and has a sprite; otherwise it
returns false and the class draws the old way. Each class keeps its code drawing intact
behind one `if not RenderAdapter.draw_sprite(...)` line, so migration and rollback are one
key in the flags file, per thing. It reads no game state and uses no randomness.

**Placeholder generator.** `pipeline/render_placeholders.gd` (outside `tools/`, which is
for tests) renders registered drawables through their real `_draw()` into a transparent
viewport at world scale, crops to the drawn pixels, and writes the PNG and the SpriteArt
with the origin. Run it with a window (`godot --path . --script
pipeline/render_placeholders.gd -- [key ...]`); the headless renderer draws nothing.

**Proof: the hub sign** (`prop_sign`, 82x81, origin (41, 81)). Captured from the same
frame drawn by code and from the sprite: 0 differing pixels in the sign's area (the only
differences in the frame are the animated player). The flag is left off, so the game
still draws the sign by code until Phase 2 migrates props.

## Design backlog: enemy silhouettes (not fixed yet)

Seven enemy groups share one body glyph in the code (EnemyArt.GLYPHS) and can only be told
apart after they act (a buff ring, a stance arc, a barrier):

| Group | Same body |
| --- | --- |
| 1 | Quarter Rest = Bandleader |
| 2 | Eighth Rest = Staccato Rest = Breathless Rest |
| 3 | Sixteenth Rest = Motif Rest |
| 4 | Tether Rest = Unison Rest |
| 5 | Half Rest ≈ Rimshot Guard |
| 6 | Echo Rest ≈ Reverb Warden |
| 7 | Whole Rest ≈ Half Rest |

Each needs a distinct silhouette when real art is drawn. The pipeline is ready for that:
every enemy already has its own sprite files and its own flag (no file is shared between
enemy types; some placeholders are byte-identical copies), so new art is a file swap.

## Phase 2.5: world text and FX (done)

**World text.** Damage numbers, float text and grade callouts, shop prices and statue names
are drawn crisp by WorldText, projected from the world (camera and shake included), snapped
to a world pixel and scaled by the whole-number scale. Switched by "world_text_ui".
Still drawn in the world: teacher names and elite names.

**FX moved to sprites** (their look is fixed, or depends only on their own clock):
- Pickups (sharp and heal): a fixed glyph; the bob stays a code offset.
- Ghost Note decoy: the player's note pulsing on a loop, 12 frames, one strip per note.
- Spawn mark: a pure function of its 0.75 s life, 12 frames, normal and elite.
- Tempest tornado: a periodic swirl, 16 frames; its end fade is a tint.

**FX left procedural** (they change with each instance, not only with time):
- Slash: arc angle, radius, thickness and progress vary per attack step and frame.
- Ring: radius varies per use (parry, cymbal, reverb, keeper landings) and grows each frame.
- Shockwave: height, direction and colour vary per wave.
- Column: length, width and orientation vary per strike.
- Pillar: height and width vary per power level; it rises and sinks.
- Trail: a line between two points that change every dash.
- Splat: each splat scatters its own drops.
- Projectiles: size and colour vary per shot; mallets, gusts and waves rotate with velocity,
  and their strokes don't scale with radius.
- Float text and damage numbers: now drawn by WorldText, not the world.

## Phase 2 summary (closed)

**The rule.** A thing became a sprite when its look is fixed, or changes only with its own
clock (a loop or a lifetime) and a small set of named states (an ink colour, open/closed,
a character). It stayed procedural when its shape depends on per-instance or per-frame
values: sizes, directions, endpoints, the beat, facing, or random scatter. Those parts
stay in code even inside a sprite-drawn thing (eyes follow facing; stems lean with speed).
Text went to the crisp UI layer (WorldText) rather than either.

**Sprites (each switchable in render_flags.tres, placeholders identical to the code look):**
- props: chests, benches, shop stands, statue bases, signs;
- background: floor tiles, clefs and time signatures, platform bodies and caps, drum pads,
  exit bars;
- all 24 enemies (bodies, accent layers, crowns; animated glyphs as frame strips);
- the 5 bosses' bodies (one per ink colour) and the Timpani's front layer;
- the 4 notes' heads;
- FX: pickups, the Ghost Note decoy, spawn marks, the Tempest tornado.

**Procedural:** paper, grain, washes, staff and bar lines, updrafts, harmonics, strings;
eyes, auras, haze, tethers, stun stars, the wind-up accent mark; boss batons, strings,
breath and blinks; player stems, flags and eyes; slash, ring, shockwave, column, pillar,
trail, splat and projectiles.

**Crisp text (WorldText):** damage numbers, float text and grade callouts, shop prices,
statue names, teacher names, elite names.

**HUD:** nothing to migrate. It has drawn at full resolution since Phase 1a; migrating it
would only re-rasterise crisp code-drawn text and icons.

**Grade callouts, judged at a glance:** the crisp "perfect!" reads at least as well as the
old one at the same size, colour and position; the old one was not punchier, only softer
(the same font rendered small and scaled up). What changed is style: smooth serif text
now reads as UI laid over a pixel world. If that matters, the fix is a pixel font for the
text layer, not going back.

**Backlog carried out of Phase 2:** the seven same-glyph enemy groups need distinct
silhouettes when real art is drawn.

## Phase 3: seasons, planes, Void

### 3.1 Seasons as data

- `Season` (`src/art/season.gd`): id, the pillar it dresses, a wash palette, a
  `SeasonParticles` set. Files in `content/art/seasons/`: autumn (Percussion, falling
  leaf-notes), summer (Wind, heat shimmer), winter (Strings, drifting frost).
  `SeasonBook.for_family()` is the only lookup; nothing branches on a season's id.
- Off switch: remove `seasons` from `render_flags.tres` and every page draws as before. Each
  particle shape has its own key (`season_leaf_note`, `season_heat_shimmer`, `season_frost`).
- Randomness: the cosmetic stream only. `Background.setup()` makes its season draws after
  all of its old ones, so the grain and wash blobs land where they always did.
- Is it a palette swap? For what seasons colour, yes: the wash blobs and particles are
  drawn in code, and the palette replaces their colour where it is chosen, not a tint over
  the finished picture. Particle sprites are one-colour white art tinted per palette entry,
  which is exact for one colour. It is **not** a palette swap for the Phase 2 sprites (floor,
  platforms, props): they are truecolour PNGs, and seasons leave them alone. Recolouring
  those would need indexed art and a lookup shader, which don't exist yet.
- Test: `pipeline/test_seasons.sh` plays the fixed-seed run (the bot from
  `tools/test_rng_streams.gd`) with seasons off, natural, and each season forced onto every
  page, one process each, and diffs the simulation fingerprints. It also checks that each
  run was actually dressed in the season it asked for. Verified that it fails: one
  `Game.stream("loot")` draw added to the season setup failed all four comparisons. The
  first version compared against "none forced" and missed that mutation (natural play
  dresses Bar I in autumn too), so its baseline is now seasons switched off.
- `SeasonBook.off` exists because writing `sprite_keys` at runtime does nothing once the
  game has loaded (the flags are a const preload): the first test and capture scripts turned
  seasons "off" that way, and the capture's "off" shots were in autumn.
- Screenshots: `pipeline/capture_seasons.gd -- <dir> <season>`, one process per season. Two
  `new_run()` calls with the same seed in one process can deal different maps, so a single
  process for all seasons put a Shop in one row and a Treasure in the others.

### 3.2 Parallax planes

- Each season has three `ParallaxPlane`s (far to near), drawn by `Background` after the
  paper and before the grain, wash and staff. A plane is a silhouette on the floor: two sine
  swells plus a row of peaks, in whole cycles per 384 px tile, so tiles join without a seam.
  Autumn: rolling hills and a treeline. Summer: haze bank, dunes, low swell. Winter: peaks,
  a pine row, a near ridge.
- `depth` is how far a plane moves with the page (0 stays on screen, 1 moves with the
  staff): a tile at depth d is shifted back by the camera's x times (1 - d). The camera
  transform includes shake, so planes shake by their depth too. No randomness: nothing is
  placed, the silhouettes are functions of x.
- Colour: the plane's palette entry, drained toward grey while the room is hushed and
  brought back by the existing wash as it is freed. Alphas 0.05 to 0.07: the first pass
  (0.10 to 0.14) muddied the whole page.
- The first pass drew each tile 8 px wider than the tile, and translucent overlaps showed
  as dark vertical bands every 384 px. Tiles are now exactly one tile wide.
- Sprites: `season_<id>_plane_<n>`, 384x600, cropped. `check_placeholders.gd` used to skip
  every cropped tile; an entry marked `whole` (its code drawing fits the crop) is now
  compared like any other. All nine planes: 0 differing pixels.

### 3.3 Void (visual only)

- The Void is not a place or a mode: `VoidLook.amount()` maps the existing graduated hush
  (`Synth.hush`, which room.gd moves between 0.2 and 1 as rests fall, and 0 when freed) to
  0..1 between `start_hush` and `full_hush`. Background only reads the hush; nothing new
  is stored or timed. Numbers in `content/art/void_look.tres`; off switch `void_look`.
- As it rises: season colours (wash, planes, particles) drain toward their own luminance
  grey (up to 0.85), particles thin to 20% (always the first ones placed, so none blink in
  or out at random), and every plane fades to one alpha (0.03): the layers merge into one
  flat tone, the opposite of what 3.2 built.
- Not done here: holding the low-pass longer. The filter's release is driven from
  `src/world/room/room.gd`, out of scope for this branch; it gets its own session.
- `pipeline/test_seasons.sh` gained a `void` run (natural seasons, Void pinned at full);
  it matches the seasons-off fingerprint like the others.
- Screenshots: `capture_seasons.gd -- <dir> natural <hush>` at 0.2, 0.6 and 1.0 in each bar.

## Phase 3 summary (closed)

- Three commits: seasons as data (3.1), parallax planes (3.2), Void (3.3). All
  presentation: cosmetic stream only, nothing in room/, tools/ or simulation files; each
  commit passed the four checks and the season isolation test (off / natural / void / each
  season forced, simulation fingerprints identical).
- Everything is reversible from `render_flags.tres`: `seasons` and `void_look` switch the
  layers, and each of the 12 season sprites (3 particle shapes, 9 plane tiles) has its own
  key and falls back to code.
- **Constraint: a season cannot recolour the Phase 2 sprites.** Floor, platforms, props,
  enemies and bosses are truecolour PNGs baked in the base palette. A season changes only
  what is drawn in code or from one-colour tinted sprites (wash, planes, particles). A
  multiply tint over the baked sprites would muddy them rather than swap their colours.
  Taking seasons further (an autumn floor, frosted platforms) needs indexed art plus a
  palette lookup shader, or one sprite set per season. Until one of those exists, a
  season is limited to the air around the ink, not the ink itself.
- Open: the Void's low-pass hold (room.gd, own session); the enemy silhouette backlog.
- Tooling lessons: a test is only trusted after it has been seen to fail (the first season
  test compared against the wrong baseline and passed a leak). Flags written at runtime
  after load do nothing (const preload), so tests use explicit static switches.

## Launch blank page (found by playing, not by any check)

- Symptom: `godot --path .` on pixel-art showed a blank page. Cause: the checkout's
  `.godot/global_script_class_cache.cfg` was missing or stale. A plain launch reads class
  names only from that file, and only the editor or `--import` rebuilds it; main.gd uses
  `WorldView`, new on this branch, so it failed to compile. Reproduced both ways: a fresh
  clone (71 script errors, starting with beat.gd; main fails the same way fresh) and a
  checkout imported on main then switched here (`Could not find type "WorldView"`).
- Fix: `./play.sh` runs an incremental `--import` then launches.
- **Lesson:** every check we ran was headless or a scripted capture in a worktree with a
  warm cache, so none of them ever saw the game the way a player launches it. Godot also
  exits 0 after script errors, so exit codes alone prove nothing.
  `pipeline/test_launch.sh [rev]` boots the real main scene from a clean clone, fresh and
  stale, and fails on any script error in the log. It failed on cea632b (both states)
  before the fix.

## Zoom out: the page as it was laid out

- 480x270 at one world unit per pixel showed about two of the five staff lines. The world
  view now shows `view` world units (1280x720, the original framing) rendered into
  `resolution` pixels (720x405, exactly 2x at 1440x810), both in
  `content/tuning/world_view_tuning.tres`. It uses the SubViewport's `size_2d_override`, so
  the room and its camera see the same 1280x720 they always did; nothing in room/ changed.
- Sprites carry a `density` (texture pixels per world unit) and are drawn at world size
  whatever it is. `render_placeholders.gd` renders at the tuning's density (0.5625 = 9/16,
  so the 16, 48 and 384 unit tiles land on 9, 27 and 216 whole pixels). After changing
  the tuning, re-render, or sprites are resampled.
- Two traps found on the way:
  - Tiled platforms came out as a staircase. At 9/16 density, texel edges fall exactly on
    pixel centres, and nearest sampling broke the tie differently in each triangle of a
    quad. `RenderAdapter.TIE_BIAS` nudges every sprite rect a hundredth of a pixel.
  - The generator and checker rendered with linear filtering while the world view is
    nearest. At density 1 that didn't matter; scaled, text glyphs (the clef blocks' 4/4)
    came out different. Both now render nearest, like the game. All 117 checked
    sprites within 2/255.
- The gate lives in `pipeline/gate.sh` now: the scratchpad copy was wiped between sessions.
