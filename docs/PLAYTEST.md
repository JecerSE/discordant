# The Discordant: playtest build

Thanks for playing. This is a work-in-progress build of a rhythm-action roguelite: you are a
quarter note that fell off the Grand Score, climbing the pillar pages (Percussion, Wind,
Strings) back to the Conductor. Attacks land harder on the beat.

## Running it

- **Windows:** unzip, run `TheDiscordant.exe`. It is not code-signed, so Windows SmartScreen
  may warn you: choose "More info", then "Run anyway".
- **Linux:** unzip, then `chmod +x TheDiscordant.x86_64` and run it. It needs OpenGL 3.3.

It is one file with everything inside; nothing else needs to sit next to it. Your progress
is saved in your user folder (Windows `%APPDATA%\Godot\app_userdata\The Discordant`,
Linux `~/.local/share/godot/app_userdata/The Discordant`).

Controls are shown in the game and can be rebound under Pause, then Controls.

## What this build is

- **The pixel pass.** The world is drawn at a low resolution and scaled up crisply, showing
  the whole five-line staff. Everything with a fixed look (props, platforms, enemies,
  bosses, the notes' heads, pickups) is now a sprite; things shaped by the moment (eyes that
  follow you, stems, slashes, auras) are still drawn live. Text stays sharp on top.
- **Seasons.** Each pillar has a season: autumn for Percussion (falling leaf-notes), summer
  for Wind (heat shimmer), winter for Strings (drifting frost), each with its own colours
  and three layers of scenery behind the staff that move at different speeds.
- **The Void.** While the Rest holds a room, the season drains toward grey, its particles
  thin out and the scenery flattens. It lifts as you clear the room.

**Deliberately unfinished.**
- The sprites are placeholders made from the old drawn art. Final art is still to come,
  and several enemies still share a silhouette until they get their own.
- The Void only affects what you see. The music does not yet stay muffled longer as it
  deepens.
- Seasons colour the air around the ink, not the ink itself: platforms, props and
  enemies look the same in every season.

## Known issues

These are recorded in the project and don't affect normal play:
- Some internal ids are still plain text rather than checked names (a code-quality gap).
- The automated full-run test isn't fully seeded, so its timings vary between runs.
- Starting two runs from the same seed in one session can deal different maps.

## Reporting back

For anything odd (a crash, a soft-lock, a room that feels wrong, a place you got lost),
please send:

1. **The build line.** Pause the game (Esc): the bottom-right corner shows
   `seed ... · rooms ... · build ...`. Copy all of it. The ending screen shows the same
   line for the run you just finished, and the title screen shows the build alone.
2. **Where you were.** The bar name at the top right (for example "Bar II: Wind"), and what
   kind of room (fight, chest, shop, boss).
3. **What happened.** What you did just before, what you expected, what you saw. A
   screenshot or a short clip helps a lot.
4. **Your machine.** Windows or Linux, and your graphics card if you know it.

Anything you felt is worth saying too: what was fun, what was confusing, where you gave up.
