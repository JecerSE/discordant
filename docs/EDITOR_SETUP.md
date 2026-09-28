# Working on The Discordant in the Godot editor

## Open the right project

Open **`~/discordant-main`** (starred in the Project Manager). It is `main`, the game as it
is now. `~/the-discordant` is the private repo's first checkout, currently on the older
`pixel-art-and-intro` branch (the earlier art pass, the cinematic prologue and varied room
shapes, not merged into main). Don't use it for main work.

## Where things are (FileSystem dock)

| Folder | What |
|---|---|
| `src/` | All game code. `src/main.tscn` is the only game scene; rooms, actors and UI are built in code (see `docs/FILE_MAP.md`). |
| `content/` | Data as `.tres`: tuning, combat sets, seasons (`content/art/seasons/`), render flags (`content/art/render_flags.tres`), sprite descriptors (`content/art/sprites/`). |
| `assets/sprites/` | The sprite PNGs (placeholders rendered from the code art until real art replaces them). |
| `gallery/` | Editor-only scenes that show all the art in the 2D view (below). Not exported. |
| `tools/` | Test suites and harnesses (`godot --headless --path . --script tools/<name>.gd`). |
| `pipeline/` | Art and build scripts: placeholders, export, gates, launch and export tests. |
| `docs/` | Design, file map, pixel-art notes, export and playtest docs. |

## Seeing everything in 2D: the gallery

The game builds its rooms in code, so opening `main.tscn` shows an empty node. To look at the
art, open a scene from `gallery/` and switch to the **2D** tab. It draws live; no need to
press Play.

| Scene | Shows |
|---|---|
| `all_art.tscn` | Every drawable that has a sprite |
| `props.tscn`, `background.tscn`, `enemies.tscn`, `bosses.tscn`, `notes.tscn`, `fx.tscn`, `season_sprites.tscn` | One family each |
| `seasons.tscn` | Each season as a page: palette, the three parallax planes, particles, staff and floor |

Select the root node and use the **Inspector**:
- `view`: Sprite, Code, or Both (code drawing left, sprite right, to compare them).
- `category`: a key prefix (`enemy_`, `boss_`, ...), or empty for everything.
- `animate`: plays animated sprites and particles.
- `reload`: tick it after re-rendering sprites (`pipeline/render_placeholders.gd`) so the
  gallery picks up the new PNGs.
- Seasons only: `scroll` slides the camera along the page (the planes move at their
  depths), `wash` is how freed the room is, and `void_amount` is how far the hush has won.

Sprites are shown with nearest filtering at the density the game renders them (720x405
pixels for a 1280x720 view), so they look as they do in play. Zoom the 2D view with the
mouse wheel; the art is at world scale.

New art appears in the gallery by itself once its script is listed in
`src/art/art_registry.gd` (the same list the sprite pipeline uses).

## Running

- **F5** runs the game (`src/main.tscn`). **F6** runs the open scene: a gallery scene
  runs too, which shows it exactly as the game's renderer draws it.
- From a terminal, run from source with `./play.sh` (it refreshes Godot's cache first). A
  bare `godot --path .` on a stale cache stops with a one-line message.

## Recommended editor settings (Editor > Editor Settings)

To apply them all at once: open `addons/editor_setup/apply_editor_settings.gd` in the
Script editor and run it with **File > Run** (Ctrl+Shift+X). It sets them through the
editor, so they are kept when it quits. (Editing the settings file by hand while the
editor runs doesn't work: the editor rewrites that file when it quits.) The settings:

- **Text Editor > Behavior > Files**: Trim Trailing Whitespace On Save on; Autosave
  Interval Secs 0 (no silent saves).
- **Text Editor > Behavior > Indent**: Type Tabs (the project uses tabs).
- **Run > Output**: Always Clear Output On Play on.
- **Run > Window Placement**: Rect = Force Maximized, if you want the game window to open
  big enough to see integer scaling at work.
- **Interface > Editor**: Save On Focus Loss off, so nothing is written behind your back
  while a terminal session is working in the same checkout.

## Don't

- **Don't save `src/main.tscn` without its script.** The root node `Main` must have
  `res://src/main.gd` attached. On 2026-09-28 an editor re-save dropped it, and the game
  opened to a plain page with no error at all. `pipeline/test_launch.sh` fails on that
  (blank frame).
- Don't edit the placeholder PNGs by hand and then re-run `render_placeholders.gd`: it
  overwrites them. Real art replaces a PNG and keeps its origin pixel (see
  `docs/PIXEL_ART_NOTES.md`).
- Don't merge into `main` from anywhere but `~/discordant-main`.
