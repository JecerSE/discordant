class_name TimpaniTuning
extends Resource
## Pattern and speed for the Hollow Timpani (issue #27: slowed down).
## Edit content/tuning/bosses/timpani_tuning.tres.

@export_group("Rhythm")
## Beats in one attack cycle for phases 1-2 and for phase 3.
@export var cycle_beats: int = 8
@export var cycle_beats_phase3: int = 4
## Beat in the cycle that shows the wind-up; the leap comes one beat later.
@export var windup_beat: int = 0
## Beat in the cycle when mallets are thrown (phases 1-2 only).
@export var mallet_beat: int = 6
## Airtime of a leap, in beats. It lands on a beat, then stands still until the next wind-up.
@export var leap_air_beats: float = 1.0
@export var leap_max_speed: float = 620.0

@export_group("Shockwaves")
@export var wave_speed: float = 380.0
@export var wave_speed_per_phase: float = 40.0
@export var wave_life: float = 2.2
@export var wave_height: float = 36.0
@export var landing_ring_radius: float = 130.0

@export_group("Mallets")
@export var mallets_phase1: int = 2
@export var mallets_phase2: int = 3
@export var mallet_speed_scale: float = 0.75
@export var mallet_lift: float = 620.0
@export var mallet_gravity: float = 1100.0
@export var mallet_damage_scale: float = 0.7

@export_group("Summons")
@export var summon_every_beats: int = 16
@export var summon_count: int = 2
@export var summon_max_alive: int = 3
