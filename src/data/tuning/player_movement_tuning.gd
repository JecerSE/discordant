class_name PlayerMovementTuning
extends Resource
## Player movement values added after the prototype (momentum, launchers, on-beat
## movement). Edit content/tuning/player_movement_tuning.tres.

@export_group("Momentum (issue #15)")
## A jump while already rising faster than jump speed adds this fraction of jump
## speed instead of replacing the rise.
@export var jump_stack_ratio: float = 0.35
## After a launch or a strong push, air steering is reduced for this long (s)...
@export var momentum_carry_time: float = 0.35
## ...to this fraction of normal air acceleration, so the momentum carries.
@export var momentum_air_control: float = 0.35
## Horizontal pushes stronger than this (px/s) start a momentum carry.
@export var momentum_push_threshold: float = 200.0
## After a launch, the grounded reset (jumps, coyote) is skipped for this long (s).
@export var launch_lock_time: float = 0.08

@export_group("On-beat movement (issue #14)")
## A jump pressed on the beat goes this much higher (fraction of jump speed).
@export var beat_jump_bonus: float = 0.12
## A dash pressed on the beat lasts this much longer (fraction).
@export var beat_dash_bonus: float = 0.35
## Landing on the beat gives a short burst of speed ("flow").
@export var flow_time: float = 0.5
## Speed bonus during flow (fraction).
@export var flow_speed_bonus: float = 0.15

@export_group("Launchers")
## Upward speed a drum pad launches you at (px/s).
@export var drum_launch_speed: float = 1180.0
## Upward acceleration inside an updraft (px/s²).
@export var updraft_accel: float = 3400.0
## Fastest rise inside an updraft (px/s).
@export var updraft_max_rise: float = 560.0
