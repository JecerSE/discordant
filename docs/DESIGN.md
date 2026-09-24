# The Discordant — design as built (v1)

This maps the pitch notes (the pillar sheet, the world notes, the rune sheet) onto what
the v1 build actually does. Anything in **TBD** is a placeholder that is easy to change. The
team should decide those.

## The world

| Pitch | In the build |
| --- | --- |
| The Grand Score: the living lives of notes | Every room is literally a staff: the five staff lines are the platforms, broken into inked segments. Bar lines, the clef and a 4/4 mark sit behind every room. |
| "The map is a line sheet, then coloured" | Rooms start grey and muffled. Clearing a room washes it in its pillar's colour (terracotta, sea-glass, rosin-violet). |
| The Rest (corruption) | Enemies are rests. While a room is hushed, the Music bus is low-passed and the lead melody is muted, so the Rest is audible silence. Clearing the room brings the song back. |
| Racism toward the pause notes | *Pause*, a half rest in the Margin, gives the intro: rests were struck out and blamed for the silence. Zephyrine (Wind) is openly prejudiced. The Luthier (String) remembers when Strings and Rests played together. The secret ending pays it off: the Rest was never the corruption. |
| The Margin (start / tutorial) | Hub room. It holds signs (controls, rhythm, the climb), Pause, a practice stand that reports early/late in ms, and statues to pick your note. |
| Percussion / Wind / String territories | Pages I–III. Each has its own song, enemy pool, champions, teacher, keeper and room layout: Percussion is low-ceilinged with drum pads, Wind is open sky with updrafts, String has harmonic nodes and humming strings. |
| The Grand Score (final zone) | Page IV: a fermata/shop choice, then the Conductor. |
| The Conductor, unaware notes are alive | Boss in four movements: Allegro (percussion leaps + baton), Adagio (string columns, line strikes), Presto (wind bullets + gusts), and a Finale at 1.25× tempo that cycles all three. |
| Secret boss: the sheet itself | Collect the three clefs the Scribble hides (one per pillar page, in a random combat room, in the highest corner, after the room is cleared). Beat the Conductor holding all three and the page tears: **The Score, Itself**. Its lines strike on the beat, notes rain from the margins, and a clef-eye drifts between lines. |
| Endings | Death = *Tacet*. Conductor = *Prima volta* (first ending, drawn with a 1. volta bracket). The Score = *Coda* (the secret ending). |

**Map style (TBD):** the notes list freezone vs Hades vs infinite rising. v1 is
**Hades-style**: each page is a branching measure of 7 rooms (combat, elite, shop, chest,
teacher, fermata, keeper) chosen on a staff-drawn map. The room code doesn't depend on the
map, so a continuous or vertical layout could replace `MapGen` without touching combat.

## The notes (characters)

| Note | Build | Unlock |
| --- | --- | --- |
| ♩ Quarter (default, lore character) | 100 HP, 2 jumps, 3-hit stem combo. *Common Time*: beat window 30% wider. Starts with Soundwave. | — |
| 𝅝 **Mundo**, Whole Note (tank) | 170 HP, 20% DR, no knockback, 1 jump, body slam; air attack = ground pound. Each Percussion rune adds +8% damage. Starts with Shockwave. | Beat the Percussion keeper |
| 𝅗𝅥 Half (balanced) | 120 HP, 2-hit combo. *Sustain*: every hit rings again half a beat later for 45%. Starts with Reverb Shield. | Beat the String keeper |
| ♪ Eighth (glass cannon) | 65 HP, 3 jumps, fast lunging 4-hit combo, dash cuts through enemies. Starts with Gale Dash. | Beat the Wind keeper |

## Rhythm (the core)

One global clock (`Beat`) drives the music, every enemy action and every boss pattern.
- Striking **on the beat** deals ×1.5 (plus runes), shows a gold ♪, and feeds several runes.
- Every enemy winds up on one beat (a red accent mark `>` appears) and strikes on the next.
- Beat judgement compensates for audio output latency. There is also a manual offset in Settings.

## Powers: the four types

Two slots (a third with the *Double Bar* rune), levels I–III (rehearse at a fermata).

- **Percussion** (scales with max HP): Shockwave, Rimshot Parry, Drumroll, Timpani Pillar (earth-bending).
- **Wind** (scales with move speed): Gale Dash, Updraft (flight), Breath Charge (hold to charge), Fade (invisibility), Tempest (the "venti ult").
- **String** (scales with rune depth, i.e. how many runes you carry): Soundwave, Echo, Soul Pull, Tether, Reverb Shield.
- **Rest** (secret, taught only by the Scribble in the margins): Fermata (stop time, bank damage), Caesura, Da Capo (rewind 3 s), Grace Note, Accelerando (double tempo for everyone), Ghost Note.

How you get them: **teachers** (four strikes on the beat on their practice stand, then pick 1 of 3), **the Scribble** (Rest powers), and each character's starting power.

## Items

- **Relics**: 18 passives from chests and B♭'s shop.
- **Champion memorabilia**: each fallen elite (two per page) drops its own piece, e.g. the Timpanist's Mallet or the Cellist's Endpin. These count toward family sets.

## Runes (the "Hades + LoL runes" system — final name TBD)

| Type | Build |
| --- | --- |
| Swappable | 3 slots, like Hollow Knight charms. Swap them in the Tab screen outside combat. Includes Metronome, Forte, Staccato, Legato, Crescendo, Accent, Dynamics, and the rare instruments **Theremin** and **Hurdy-Gurdy**. |
| Family (instrument) | Percussion: Bass Drum, Snare Drum, Cymbal, Timpani. Wind: Piccolo, Oboe, Trumpet, Flute. String: Violin, Guitar, Harp. **Piano** counts as both Percussion and String. Two or three of a family wake a **set bonus**. |
| Dissonance | Equipping rival families together is slightly out of tune (a smaller beat window), but something new happens: *Thunderclap* (Perc+Wind), *Aeolian Harp* (Wind+String), *Prepared Piano* (String+Perc), *Cacophony* (all three). |
| Pause runes | Whole / Half / Quarter / Eighth Rest and Fermata. These are support effects: parry window, dash recovery, beat window, i-frames, cooldowns. |
| Permanent | Keeper gifts, locked for the run. Includes the form changers **Diminution** (shrink, faster, bonus damage vs bigger enemies), **Augmentation** (grow, tanky) and **Dotted Rhythm** (everything lasts 50% longer), plus Key Signature, 4/4, Coda, Double Bar, Repeat Sign and Segno. |
| Margin | Found only in the margins (the Scribble), rarely in chests or shops. Each breaks a rule: Tritone, Glass Harmonica, Out of Tune, 4'33", Syncopation, Kazoo. |

## Enemies (the Rests)

| Page | Minions | Champions (elites) | Keeper |
| --- | --- | --- | --- |
| I Percussion | Quarter Rest (walker), Snare Rest (hops; each landing sends a wave), Whole Rest (drops from lines), Half Rest (charger), **Rimshot Guard** (blocks off-beat hits; an on-beat hit shatters its stance), **Bandleader** (buffs allies) | Fallen Timpanist, Fallen Cymbalist | The Hollow Timpani |
| II Wind | Eighth Rest (swooper, rising and diving), Sixteenth Rest (shooter), Gust Rest (full-body discharge that launches you), **Staccato Rest** (long burst dash, interruptible), **Breathless Rest** (phases invisible; only area attacks reach it, stuns reveal it), **Breath Reed** (powers every wind rest; break it to stun them all and strip their buffs) | Fallen Piper, Fallen Hornist | The Breathless Flute |
| III String | Tether Rest (pulls you in), Echo Rest (charged shot that bounces off surfaces), **Motif Rest** (waves mark you; the 3rd mark resolves for big damage), **Unison Rest** (binds you; while bound, every hit you land on it lands on you), **Reverb Warden** (a pulsing barrier reflects shots and staggers strikers; hit it between pulses), Sixteenth Rest | Fallen Violist, Fallen Cellist | The Unstrung Harp |

The first time you meet a Rest with a trick, a toast explains the trick.

## Open (TBD)

- The game title (working title: *The Discordant*) and the rune system's name.
- Map structure (see above).
- The rune expansion document: more instruments. Add them to `Content.RUNES`; flags are wired in `player.gd` and `powers.gd`.
- Art: everything is drawn in code (ink on paper), so replacing it with sprites is per-glyph work.
- Lore depth for the Rest (the notes say "to be expanded").
