# Exporting a playtest build

## Engine and templates

| | Version string | Source commit |
|---|---|---|
| Editor used here | `4.7.2.stable.arch_linux` (CachyOS `cachyos-extra-znver4` 4.7.2-1.1) | `ed1daf0bf001b61586d9930840f2f1394092c079` |
| Export templates | `4.7.2.stable.official` (`~/.local/share/godot/export_templates/4.7.2.stable/`, release only: `linux_release.x86_64`, `windows_release_x86_64.exe`) | `ed1daf0bf001b61586d9930840f2f1394092c079` |

Godot matches templates by the `4.7.2.stable` directory name only. The commit hash baked
into each binary is what proves a match: `strings <binary> | grep -E '^[0-9a-f]{40}$'`.
Both are the same commit. The official 4.7.2 editor, run against the same project, also
produced the reference fingerprint below.

## Build

```
pipeline/export.sh        # build/linux/TheDiscordant.x86_64, build/windows/TheDiscordant.exe
pipeline/test_export.sh   # the checks below, on the Linux binary
```

Presets live in `export_presets.cfg`: release template, pck embedded (one file per
platform), `all_resources`, excluding `pipeline/*`, `docs/*` and `addons/*`. `addons/` holds the
editor-only build-stamp plugin. `tools/` is included because the fingerprint check runs its
harness inside the export.

**Build stamp.** `addons/build_stamp` adds `res://build_stamp.txt` to every export:
`<short sha>[+dirty] <YYYY-MM-DD>`. It covers exports from `--export-release` and from the
editor alike. The title screen shows it bottom-right; a run from source shows "source
build". `+dirty` means the export was made with uncommitted changes, so don't ship one.

**Boot cache check.** `src/autoload/boot.gd` returns at once when
`OS.has_feature("template")`, which is true in every exported build. The pack's class list
and imports are baked, so it has nothing to check there.

## What `pipeline/test_export.sh` proves

Every run gets a throwaway `XDG_DATA_HOME`, so `user://` never reaches the real save. It
refuses to run on a locked screen (see `pipeline/display_check.sh`).

- **a)** The binary alone in an empty directory, in a real window, exits 0 with no script
  or load errors and draws a non-blank last frame. With an empty `user://` that is the
  first-launch prologue over the title.
- **b)** The binary runs the fixed-seed fingerprint harness (`tools/test_rng_streams.gd`)
  and matches `pipeline/fingerprint_reference.json` byte for byte. Release templates ignore
  `--script`, so an `override.cfg` beside the binary makes the harness the main loop
  (`application/run/main_loop_type="RngFingerprint"`). The shipped binary is unmodified.
- **c)** The same way, `tools/export_probe.gd` reads the settings the pixel art depends on
  inside the export: stretch mode and aspect, pixel snapping, world resolution and view,
  nearest filtering on the world view, no mipmaps and lossless sprite textures. They must
  read the same as from source.

Reference fingerprint (`pipeline/fingerprint_reference.json`, fixed seed 20260926):
sha256 `f17514b1d532dd8b8bc7ab7ab0da004f9f3364b41f5861197868c76f7932127a` (since the beat clock moved to the physics tick; before that `a583127030a9b313943cefaccdaeb2803136f13bf86b81f86a5b74fba94236ac`).

## Found while building this

- The first harness run inside an export wrote to the **real save**. `Game` switched to the
  test save only when `--script` was on the command line, and the `override.cfg` route has
  none. The save was restored from the snapper snapshot taken before the run. `Game` now
  also uses the test save whenever the main loop is a script, and every launch test sets
  its own `XDG_DATA_HOME`.
- The export's first fingerprint differed (`d4b418d3…`), and it was not the export's
  fault. Under `override.cfg` the engine also loads the project's main scene. Its hidden
  title screen took the bot's button presses as "Begin" and sent the game to the hub
  mid-fight, so every room restarted the run. Under `--script` no main scene is loaded.
  The harness now frees any auto-loaded scene first. Ruled out on the way: the export pack
  (the editor running the exported pck matched) and the editor build (the official editor
  matched too).

## The checks, each seen to fail (2026-09-28, on ba69be1's export)

| Deliberate break | a) title | b) fingerprint | c) settings |
|---|---|---|---|
| Wrong template (pack header patched to engine 4.9.2, as a mismatched template would see it) | FAILED: exit 1, no frame | FAILED: exit 1, no fingerprint | FAILED: nothing read |
| Stripped resource (`content/tuning/world_view_tuning.tres` excluded from the export) | FAILED: 3 load errors (its frame alone would have passed) | FAILED: `1d671e48…` | FAILED: probe segfaults |
| none (restored) | ok | ok, `a583127030a9b313…` | ok, 9 settings |

- **Boot guard:** with `_stale()` forced to report a stale cache, the guarded export ran as
  normal (exit 0, no message). The same export without the `template` guard printed the
  message and exited 1. So the guard, and not a clean cache, is what keeps it silent in an
  export.
- **Screen-lock precheck:** with `loginctl` reporting `LockedHint=yes` (a stand-in on
  `PATH`, since a test can't lock the session), `test_launch.sh` and `test_export.sh` both
  exit 2 with "REFUSED: the screen is locked…". The real, unlocked session passes. The real
  locked case, seen earlier the same day, had produced blank frames reported as failures.
