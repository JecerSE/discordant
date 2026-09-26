class_name MusicTuning
extends Resource
## How the music reacts to play (issue #13). Edit content/tuning/music_tuning.tres.

## While a room still has rests in it, the music never clears past this much muffle.
@export var min_combat_hush: float = 0.2
## How fast the muffle follows the room (hush units per second).
@export var hush_follow_speed: float = 0.8
## Fade out, switch songs, fade in when moving between bars (s, each way).
@export var crossfade_time: float = 0.35
## How far the music dips during a crossfade (dB).
@export var crossfade_depth_db: float = -30.0
